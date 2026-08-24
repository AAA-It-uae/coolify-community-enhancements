#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=/var/www/html
CONTAINER=${COOLIFY_CONTAINER:-coolify}
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="/root/coolify-community-backups/dashboard-performance-$STAMP"
TMP="$(mktemp -d)"

section(){ printf '\n===== %s =====\n' "$1"; }

[[ "${EUID:-$(id -u)}" -eq 0 ]] || { echo "Run as root."; exit 2; }
docker inspect "$CONTAINER" >/dev/null 2>&1 || { echo "Coolify container '$CONTAINER' not found."; exit 3; }
[[ "$(docker inspect -f '{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null || true)" == "healthy" ]] || {
  echo "Coolify container is not healthy; refusing to patch."; exit 4;
}

FILES=(
  resources/views/livewire/deployments-indicator.blade.php
  resources/views/livewire/dashboard/active-deployments.blade.php
)
OPTIONAL=(
  app/Support/LocalProjectStatus.php
  resources/views/livewire/local-server-vitals.blade.php
)

mkdir -p "$BACKUP" "$TMP"
for rel in "${FILES[@]}" "${OPTIONAL[@]}"; do
  if docker exec "$CONTAINER" test -f "$ROOT/$rel"; then
    mkdir -p "$BACKUP/$(dirname "$rel")" "$TMP/$(dirname "$rel")"
    docker cp "$CONTAINER:$ROOT/$rel" "$BACKUP/$rel"
    cp "$BACKUP/$rel" "$TMP/$rel"
  fi
done

for rel in "${FILES[@]}"; do
  [[ -f "$TMP/$rel" ]] || { echo "Required file missing: $rel"; exit 5; }
done

echo "Backup: $BACKUP"

rollback(){
  echo "Rolling back..."
  while IFS= read -r -d '' file; do
    rel="${file#$BACKUP/}"
    docker cp "$file" "$CONTAINER:$ROOT/$rel" >/dev/null 2>&1 || true
  done < <(find "$BACKUP" -type f -print0)
  docker exec "$CONTAINER" php artisan optimize:clear >/dev/null 2>&1 || true
  docker restart "$CONTAINER" >/dev/null 2>&1 || true
}
trap 'rc=$?; rm -rf "$TMP"; if ((rc!=0)); then rollback; fi; exit $rc' EXIT

section "Patch"
python3 - "$TMP" <<'PY'
from pathlib import Path
import sys
root=Path(sys.argv[1])

def replace_required(path, old, new, label):
    p=root/path
    s=p.read_text()
    if new in s:
        print(f"{label}=already")
        return
    if old not in s:
        raise SystemExit(f"{label}: expected source anchor not found")
    p.write_text(s.replace(old,new,1))
    print(f"{label}=patched")

# Global deployments indicator: 3s -> 10s.
replace_required(
    Path('resources/views/livewire/deployments-indicator.blade.php'),
    'wire:poll.3000ms',
    'wire:poll.10000ms',
    'deployment_indicator_poll'
)

# Dashboard active deployments: 3s -> 10s.
replace_required(
    Path('resources/views/livewire/dashboard/active-deployments.blade.php'),
    'wire:poll.3000ms',
    'wire:poll.10000ms',
    'dashboard_deployments_poll'
)

# Optional community live-vitals component: 2s -> 5s.
p=root/'resources/views/livewire/local-server-vitals.blade.php'
if p.exists():
    s=p.read_text()
    if 'wire:poll.2s="refreshVitals"' in s:
        p.write_text(s.replace('wire:poll.2s="refreshVitals"','wire:poll.5s="refreshVitals"',1))
        print('server_vitals_poll=patched')
    elif 'wire:poll.5s="refreshVitals"' in s:
        print('server_vitals_poll=already')
    else:
        print('server_vitals_poll=skipped_unknown_source')

# Optional LocalProjectStatus helper: add a short-lived result cache.
p=root/'app/Support/LocalProjectStatus.php'
if p.exists():
    s=p.read_text()
    if 'local-project-status:v2:' in s:
        print('project_status_cache=already')
    else:
        import_anchor='use Illuminate\\Support\\Collection;\n'
        guard='''        if ($projects->isEmpty()) {\n            return [];\n        }\n\n'''
        old_return='''        return $loaded->mapWithKeys(function (Project $project): array {\n            return [$project->uuid => self::forLoadedProject($project)];\n        })->all();'''
        if import_anchor not in s or guard not in s or old_return not in s:
            raise SystemExit('project_status_cache: expected source anchors not found')
        if 'use Illuminate\\Support\\Facades\\Cache;' not in s:
            s=s.replace(import_anchor, import_anchor+'use Illuminate\\Support\\Facades\\Cache;\n', 1)
        s=s.replace(guard, guard+'''        $cacheKey = 'local-project-status:v2:'.md5($projects->pluck('id')->sort()->values()->implode(','));\n        $cached = Cache::get($cacheKey);\n        if (is_array($cached)) {\n            return $cached;\n        }\n\n''', 1)
        s=s.replace(old_return, '''        $result = $loaded->mapWithKeys(function (Project $project): array {\n            return [$project->uuid => self::forLoadedProject($project)];\n        })->all();\n\n        Cache::put($cacheKey, $result, 5);\n\n        return $result;''', 1)
        p.write_text(s)
        print('project_status_cache=patched ttl=5s')
PY

section "Apply"
for rel in "${FILES[@]}" "${OPTIONAL[@]}"; do
  [[ -f "$TMP/$rel" ]] || continue
  docker cp "$TMP/$rel" "$CONTAINER:$ROOT/$rel"
done

section "Validate"
docker exec "$CONTAINER" grep -q 'wire:poll.10000ms' "$ROOT/resources/views/livewire/deployments-indicator.blade.php"
docker exec "$CONTAINER" grep -q 'wire:poll.10000ms' "$ROOT/resources/views/livewire/dashboard/active-deployments.blade.php"
if docker exec "$CONTAINER" test -f "$ROOT/app/Support/LocalProjectStatus.php"; then
  docker exec "$CONTAINER" php -l "$ROOT/app/Support/LocalProjectStatus.php"
fi
docker exec "$CONTAINER" php artisan optimize:clear >/dev/null
docker exec "$CONTAINER" php artisan view:cache >/dev/null

docker restart "$CONTAINER" >/dev/null
for _ in $(seq 1 60); do
  [[ "$(docker inspect -f '{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null || true)" == healthy ]] && break
  sleep 2
done
[[ "$(docker inspect -f '{{.State.Health.Status}}' "$CONTAINER")" == healthy ]]

echo "PASS: dashboard performance tuning applied"
echo "Backup: $BACKUP"
trap - EXIT
rm -rf "$TMP"
