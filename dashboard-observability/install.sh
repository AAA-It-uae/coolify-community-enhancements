#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=/var/www/html
CONTAINER=${COOLIFY_CONTAINER:-coolify}
EXPECTED_IMAGE=${EXPECTED_COOLIFY_IMAGE:-docker.io/coollabsio/coolify:4.3.10}
BASE_URL="https://raw.githubusercontent.com/AAA-It-uae/coolify-community-enhancements/main/dashboard-observability/files"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="/root/coolify-community-backups/dashboard-observability-$STAMP"
WORK="$(mktemp -d)"

[[ "${EUID:-$(id -u)}" -eq 0 ]] || { echo "Run as root."; exit 2; }
for cmd in docker curl python3; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Required command not found: $cmd"; exit 3; }
done
docker inspect "$CONTAINER" >/dev/null 2>&1 || { echo "Coolify container '$CONTAINER' not found."; exit 4; }
IMAGE="$(docker inspect -f '{{.Config.Image}}' "$CONTAINER")"
[[ "$IMAGE" == "$EXPECTED_IMAGE" ]] || {
  echo "Unsupported image: $IMAGE"
  echo "Tested image: $EXPECTED_IMAGE"
  echo "Refusing to apply a version-specific patch."
  exit 5
}
[[ "$(docker inspect -f '{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null || true)" == healthy ]] || {
  echo "Coolify is not healthy; refusing to patch."; exit 6;
}

EXISTING=(
  resources/views/layouts/app.blade.php
  app/Livewire/Dashboard.php
  resources/views/livewire/dashboard.blade.php
  app/Livewire/Project/Index.php
  resources/views/livewire/project/index.blade.php
)
NEW=(
  app/Livewire/LocalServerVitals.php
  resources/views/livewire/local-server-vitals.blade.php
  app/Support/LocalProjectStatus.php
)

mkdir -p "$BACKUP" "$WORK"
for rel in "${EXISTING[@]}"; do
  docker exec "$CONTAINER" test -f "$ROOT/$rel" || { echo "Missing required file: $rel"; exit 7; }
  mkdir -p "$BACKUP/$(dirname "$rel")" "$WORK/$(dirname "$rel")"
  docker cp "$CONTAINER:$ROOT/$rel" "$BACKUP/$rel"
  cp "$BACKUP/$rel" "$WORK/$rel"
done

# Preserve pre-existing community component files as well, making re-runs rollback-safe.
for rel in "${NEW[@]}"; do
  if docker exec "$CONTAINER" test -f "$ROOT/$rel"; then
    mkdir -p "$BACKUP/$(dirname "$rel")"
    docker cp "$CONTAINER:$ROOT/$rel" "$BACKUP/$rel"
  fi
done

mkdir -p "$WORK/app/Livewire" "$WORK/app/Support" "$WORK/resources/views/livewire"
curl -fsSL "$BASE_URL/LocalServerVitals.php" -o "$WORK/app/Livewire/LocalServerVitals.php"
curl -fsSL "$BASE_URL/LocalProjectStatus.php" -o "$WORK/app/Support/LocalProjectStatus.php"
curl -fsSL "$BASE_URL/local-server-vitals.blade.php" -o "$WORK/resources/views/livewire/local-server-vitals.blade.php"

echo "Backup: $BACKUP"

rollback(){
  echo "Rolling back..."
  for rel in "${EXISTING[@]}"; do
    [[ -f "$BACKUP/$rel" ]] && docker cp "$BACKUP/$rel" "$CONTAINER:$ROOT/$rel" >/dev/null 2>&1 || true
  done
  for rel in "${NEW[@]}"; do
    if [[ -f "$BACKUP/$rel" ]]; then
      docker cp "$BACKUP/$rel" "$CONTAINER:$ROOT/$rel" >/dev/null 2>&1 || true
    else
      docker exec "$CONTAINER" rm -f "$ROOT/$rel" >/dev/null 2>&1 || true
    fi
  done
  docker exec "$CONTAINER" php artisan optimize:clear >/dev/null 2>&1 || true
  docker restart "$CONTAINER" >/dev/null 2>&1 || true
}
trap 'rc=$?; rm -rf "$WORK"; if ((rc!=0)); then rollback; fi; exit $rc' EXIT

python3 - "$WORK" <<'PY'
from pathlib import Path
import sys
r=Path(sys.argv[1])

def once(rel, old, new, label):
    p=r/rel
    s=p.read_text()
    if new in s:
        print(label+'=already')
        return
    if old not in s:
        raise SystemExit('anchor not found: '+label)
    p.write_text(s.replace(old,new,1))
    print(label+'=patched')

once(
    'resources/views/layouts/app.blade.php',
    'class="relative flex min-w-0 flex-1 items-center"',
    'class="relative flex min-w-0 flex-1 items-center overflow-hidden pr-2"',
    'breadcrumb_collision_guard'
)

once(
    'resources/views/layouts/app.blade.php',
    '                    {{-- Dev Server-Timing HUD docks here (local only; empty in production) --}}',
    '                    <livewire:local-server-vitals />\n                    {{-- Dev Server-Timing HUD docks here (local only; empty in production) --}}',
    'global_live_hud'
)

p=r/'app/Livewire/Dashboard.php'
s=p.read_text()
if 'use App\\Support\\LocalProjectStatus;' not in s:
    anchor='use App\\Models\\Server;\n'
    if anchor not in s: raise SystemExit('dashboard import anchor not found')
    s=s.replace(anchor, anchor+'use App\\Support\\LocalProjectStatus;\n',1)
if 'public array $projectStatuses = [];' not in s:
    anchor='    public Collection $privateKeys;\n'
    if anchor not in s: raise SystemExit('dashboard property anchor not found')
    s=s.replace(anchor, anchor+'\n    public array $projectStatuses = [];\n',1)
if '$this->projectStatuses = LocalProjectStatus::forProjects($this->projects);' not in s:
    anchor='''            ])\n            ->get();\n    }'''
    if anchor not in s: raise SystemExit('dashboard mount anchor not found')
    s=s.replace(anchor, '''            ])\n            ->get();\n        $this->projectStatuses = LocalProjectStatus::forProjects($this->projects);\n    }''',1)
p.write_text(s)

once(
    'resources/views/livewire/dashboard.blade.php',
    '''                                    <p class="mt-0.5 truncate text-[11px] text-neutral-500 dark:text-fg-faint">\n                                        {{ $project->description ?: 'No description' }}\n                                    </p>''',
    '''                                    <p class="mt-0.5 truncate text-[11px] text-neutral-500 dark:text-fg-faint">\n                                        {{ $project->description ?: 'No description' }}\n                                    </p>\n                                    @php\n                                        $uiStatus = $projectStatuses[$project->uuid] ?? ['label' => 'Unknown', 'type' => 'neutral'];\n                                        [$uiColor, $uiDot, $uiBg, $uiBorder] = match ($uiStatus['type']) {\n                                            'success' => ['#047857', '#10b981', 'rgba(16,185,129,.07)', 'rgba(16,185,129,.22)'],\n                                            'warning' => ['#b45309', '#f59e0b', 'rgba(245,158,11,.07)', 'rgba(245,158,11,.22)'],\n                                            'error' => ['#b91c1c', '#ef4444', 'rgba(239,68,68,.07)', 'rgba(239,68,68,.22)'],\n                                            default => ['#525252', '#a3a3a3', 'rgba(115,115,115,.05)', 'rgba(115,115,115,.18)'],\n                                        };\n                                    @endphp\n                                    <span class="mt-2 inline-flex w-fit items-center gap-1.5 rounded-full border px-2 py-0.5 text-[10.5px] font-medium"\n                                        style="color:{{ $uiColor }};background:{{ $uiBg }};border-color:{{ $uiBorder }}"\n                                        title="Project status: {{ $uiStatus['label'] }}">\n                                        <span class="size-1.5 rounded-full" style="background:{{ $uiDot }}"></span>\n                                        {{ $uiStatus['label'] }}\n                                    </span>''',
    'dashboard_project_badge'
)

p=r/'app/Livewire/Project/Index.php'
s=p.read_text()
if 'use App\\Support\\LocalProjectStatus;' not in s:
    anchor='use App\\Models\\Project;\n'
    if anchor not in s: raise SystemExit('project index import anchor not found')
    s=s.replace(anchor, anchor+'use App\\Support\\LocalProjectStatus;\n',1)
if 'public array $projectStatuses = [];' not in s:
    anchor='    public $projects;\n'
    if anchor not in s: raise SystemExit('project index property anchor not found')
    s=s.replace(anchor, anchor+'\n    public array $projectStatuses = [];\n',1)
if '$this->projectStatuses = LocalProjectStatus::forProjects($this->projects);' not in s:
    anchor='''            ])\n            ->get();\n    }'''
    if anchor not in s: raise SystemExit('project index mount anchor not found')
    s=s.replace(anchor, '''            ])\n            ->get();\n        $this->projectStatuses = LocalProjectStatus::forProjects($this->projects);\n    }''',1)
if "'statusLabel' =>" not in s:
    anchor="""                    'resourceCount' => $resourceCount,\n                    'settingsHref' => auth()->user()->can('update', $project)"""
    if anchor not in s: raise SystemExit('project index payload anchor not found')
    s=s.replace(anchor, """                    'resourceCount' => $resourceCount,\n                    'statusLabel' => data_get($this->projectStatuses, $project->uuid.'.label', 'Unknown'),\n                    'statusType' => data_get($this->projectStatuses, $project->uuid.'.type', 'neutral'),\n                    'settingsHref' => auth()->user()->can('update', $project)""",1)
p.write_text(s)

once(
    'resources/views/livewire/project/index.blade.php',
    '''                                    <p class="mt-0.5 truncate text-[11px] text-neutral-500 dark:text-fg-faint"\n                                        x-text="project.description || 'No description'"></p>''',
    '''                                    <p class="mt-0.5 truncate text-[11px] text-neutral-500 dark:text-fg-faint"\n                                        x-text="project.description || 'No description'"></p>\n                                    <span class="mt-2 inline-flex w-fit items-center gap-1.5 rounded-full border px-2 py-0.5 text-[10.5px] font-medium"\n                                        :style="project.statusType === 'success' ? 'color:#047857;background:rgba(16,185,129,.07);border-color:rgba(16,185,129,.22)' : project.statusType === 'warning' ? 'color:#b45309;background:rgba(245,158,11,.07);border-color:rgba(245,158,11,.22)' : project.statusType === 'error' ? 'color:#b91c1c;background:rgba(239,68,68,.07);border-color:rgba(239,68,68,.22)' : 'color:#525252;background:rgba(115,115,115,.05);border-color:rgba(115,115,115,.18)'"\n                                        :title="`Project status: ${project.statusLabel}`">\n                                        <span class="size-1.5 rounded-full"\n                                            :style="project.statusType === 'success' ? 'background:#10b981' : project.statusType === 'warning' ? 'background:#f59e0b' : project.statusType === 'error' ? 'background:#ef4444' : 'background:#a3a3a3'"></span>\n                                        <span x-text="project.statusLabel"></span>\n                                    </span>''',
    'project_grid_status_badge'
)
PY

for rel in "${NEW[@]}"; do
  docker exec "$CONTAINER" mkdir -p "$ROOT/$(dirname "$rel")"
  docker cp "$WORK/$rel" "$CONTAINER:$ROOT/$rel"
done
for rel in "${EXISTING[@]}"; do
  docker cp "$WORK/$rel" "$CONTAINER:$ROOT/$rel"
done

for rel in app/Support/LocalProjectStatus.php app/Livewire/LocalServerVitals.php app/Livewire/Dashboard.php app/Livewire/Project/Index.php; do
  docker exec "$CONTAINER" php -l "$ROOT/$rel"
done

docker exec "$CONTAINER" grep -q 'diskTotalGiB' "$ROOT/app/Livewire/LocalServerVitals.php"
docker exec "$CONTAINER" grep -q 'local-vitals-disk' "$ROOT/resources/views/livewire/local-server-vitals.blade.php"
docker exec "$CONTAINER" grep -q 'wire:poll.15s' "$ROOT/resources/views/livewire/local-server-vitals.blade.php"

docker exec "$CONTAINER" php artisan optimize:clear >/dev/null
docker exec "$CONTAINER" php artisan view:cache >/dev/null

# Validate the same root-filesystem source used by the Livewire component.
docker exec "$CONTAINER" php -r '
$t=(float)(disk_total_space("/")?:0);$f=(float)(disk_free_space("/")?:0);$f=min($t,max(0,$f));$u=max(0,$t-$f);
if($t<=0||$u<0||$f<0){fwrite(STDERR,"invalid disk metrics\n");exit(1);}
echo "disk_total_gib=".round($t/1073741824,1)." disk_used_gib=".round($u/1073741824,1)." disk_free_gib=".round($f/1073741824,1)."\n";
'

docker restart "$CONTAINER" >/dev/null
for _ in $(seq 1 60); do
  [[ "$(docker inspect -f '{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null || true)" == healthy ]] && break
  sleep 2
done
[[ "$(docker inspect -f '{{.State.Health.Status}}' "$CONTAINER")" == healthy ]]

[[ "$(docker exec "$CONTAINER" grep -c '<livewire:local-server-vitals' "$ROOT/resources/views/layouts/app.blade.php")" == 1 ]]
[[ "$(docker exec "$CONTAINER" grep -c 'Project status:' "$ROOT/resources/views/livewire/dashboard.blade.php")" -ge 1 ]]
[[ "$(docker exec "$CONTAINER" grep -c 'project.statusLabel' "$ROOT/resources/views/livewire/project/index.blade.php")" -ge 1 ]]

echo "PASS: dashboard observability applied (CPU/RAM/DISK/load + project status)"
echo "Backup: $BACKUP"
trap - EXIT
rm -rf "$WORK"
