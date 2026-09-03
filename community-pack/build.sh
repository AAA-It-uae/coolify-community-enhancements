#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT="${1:-$SCRIPT_DIR/.build/coolify-v4.3.15}"
UPSTREAM_TAG='v4.3.15'
UPSTREAM_SHA='b8866b87e8e855e041c21330352ca615521afed3'
PROJECT_UX_SHA='e24a963ad80001475f379caaf5fd9e4252ca3c28'

command -v git >/dev/null
command -v python3 >/dev/null
command -v curl >/dev/null

rm -rf "$OUT"
mkdir -p "$(dirname "$OUT")"
git clone --quiet --depth 1 --branch "$UPSTREAM_TAG" https://github.com/coollabsio/coolify.git "$OUT"
cd "$OUT"

[[ "$(git rev-parse HEAD)" == "$UPSTREAM_SHA" ]] || {
    echo 'Upstream tag moved. Aborting.' >&2
    exit 50
}

git config user.name 'community-pack-builder'
git config user.email 'actions@users.noreply.github.com'
git fetch --quiet --depth=2 https://github.com/mtalavi/coolify.git "$PROJECT_UX_SHA"
git cherry-pick --no-commit FETCH_HEAD >/dev/null

git restore --staged --worktree tests/Feature/ProjectDashboardUxTest.php 2>/dev/null || true

python3 - app/Support/ProjectDomainAggregator.php <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
s = s.replace("'project-dashboard-domains:v1:'", "'project-dashboard-domains:v3:'", 1)
s = s.replace(
    'return Cache::remember($cacheKey, 10, function () use ($projects, $projectIds): array {',
    'return Cache::remember($cacheKey, 5, function () use ($projects, $projectIds): array {',
    1,
)

select_anchor = '''                    'environments.project_id as project_id',\n                    'applications.fqdn as fqdn',\n                    'applications.docker_compose_domains as docker_compose_domains',\n'''
select_replacement = '''                    'environments.project_id as project_id',\n                    'applications.build_pack as build_pack',\n                    'applications.fqdn as fqdn',\n                    'applications.docker_compose_domains as docker_compose_domains',\n'''
if select_anchor not in s:
    raise SystemExit('Domain application select anchor changed upstream.')
s = s.replace(select_anchor, select_replacement, 1)

loop_anchor = '''            foreach ($applications as $application) {\n                $projectId = (int) $application->project_id;\n                self::addRawDomains($byProjectId[$projectId], $application->fqdn);\n                self::addComposeDomains($byProjectId[$projectId], $application->docker_compose_domains);\n            }\n\n'''
loop_replacement = '''            foreach ($applications as $application) {\n                $projectId = (int) $application->project_id;\n                if ($application->build_pack === 'dockercompose') {\n                    self::addComposeDomains($byProjectId[$projectId], $application->docker_compose_domains);\n                } else {\n                    self::addRawDomains($byProjectId[$projectId], $application->fqdn);\n                }\n            }\n\n'''
if loop_anchor not in s:
    raise SystemExit('Domain aggregation loop anchor changed upstream.')
s = s.replace(loop_anchor, loop_replacement, 1)

method_anchor = '''    private static function addComposeDomains(array &$bucket, mixed $raw): void\n    {\n        if (! is_string($raw) || trim($raw) === '') {\n            return;\n        }\n\n        $decoded = json_decode($raw, true);\n        if (! is_array($decoded)) {\n            return;\n        }\n\n        array_walk_recursive($decoded, function ($value) use (&$bucket): void {\n            if (is_string($value)) {\n                self::addRawDomains($bucket, $value);\n            }\n        });\n    }\n\n'''
method_replacement = '''    private static function addComposeDomains(array &$bucket, mixed $raw): void\n    {\n        if (! is_string($raw) || trim($raw) === '') {\n            return;\n        }\n\n        $decoded = json_decode($raw, true);\n        if (! is_array($decoded)) {\n            return;\n        }\n\n        foreach ($decoded as $entry) {\n            if (! is_array($entry)) {\n                continue;\n            }\n\n            $domainString = $entry['domain'] ?? null;\n            if (is_string($domainString)) {\n                self::addRawDomains($bucket, $domainString);\n            }\n        }\n    }\n\n'''
if method_anchor not in s:
    raise SystemExit('Compose domain helper anchor changed upstream.')
s = s.replace(method_anchor, method_replacement, 1)
p.write_text(s)
PY

python3 - resources/views/livewire/project/index.blade.php resources/views/livewire/dashboard.blade.php <<'PY'
from pathlib import Path
import sys
project = Path(sys.argv[1])
s = project.read_text()
old = ": 'color:#525252;background:rgba(115,115,115,.05);border-color:rgba(115,115,115,.18)'"
new = ": project.statusLabel === 'Stopped' ? 'color:#525252;background:rgba(115,115,115,.05);border-color:rgba(239,68,68,.48)' : 'color:#525252;background:rgba(115,115,115,.05);border-color:rgba(115,115,115,.18)'"
if s.count(old) < 2:
    raise SystemExit('Project status style anchor changed upstream.')
project.write_text(s.replace(old, new))

dash = Path(sys.argv[2])
s = dash.read_text()
anchor = """                                            default => ['#525252', '#a3a3a3', 'rgba(115,115,115,.05)', 'rgba(115,115,115,.18)'],\n                                        };\n                                    @endphp"""
replacement = """                                            default => ['#525252', '#a3a3a3', 'rgba(115,115,115,.05)', 'rgba(115,115,115,.18)'],\n                                        };\n                                        if (($projectStatus['label'] ?? '') === 'Stopped') {\n                                            $statusBorder = 'rgba(239,68,68,.48)';\n                                        }\n                                    @endphp"""
if anchor not in s:
    raise SystemExit('Dashboard status style anchor changed upstream.')
dash.write_text(s.replace(anchor, replacement, 1))
PY

mkdir -p app/Livewire resources/views/livewire resources/views/components
cp "$REPO_ROOT/dashboard-observability/files/LocalServerVitals.php" app/Livewire/LocalServerVitals.php
cp "$REPO_ROOT/dashboard-observability/files/local-server-vitals.blade.php" resources/views/livewire/local-server-vitals.blade.php
cp "$REPO_ROOT/interactive-magnifier/files/local-magnifier.blade.php" resources/views/components/local-magnifier.blade.php

python3 - resources/views/layouts/app.blade.php <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
anchor = '''                    {{-- Dev Server-Timing HUD docks here (local only; empty in production) --}}\n'''
insert = '''                    <x-local-magnifier />\n                    @if (isInstanceAdmin() && ! isCloud())\n                        <livewire:local-server-vitals />\n                    @endif\n                    {{-- Dev Server-Timing HUD docks here (local only; empty in production) --}}\n'''
if s.count(anchor) != 1:
    raise SystemExit('Top-bar anchor changed upstream.')
if '<livewire:local-server-vitals' in s or '<x-local-magnifier' in s:
    raise SystemExit('Community pack markers already exist.')
p.write_text(s.replace(anchor, insert, 1))
PY

python3 - resources/views/livewire/deployments-indicator.blade.php resources/views/livewire/dashboard/active-deployments.blade.php <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
old = '<div wire:poll.3000ms x-on:livewire:navigated.window="'
new = '<div @if ($this->deploymentCount > 0) wire:poll.5000ms @else wire:poll.60000ms @endif x-on:livewire:navigated.window="'
if s.count(old) != 1:
    raise SystemExit('Deployment polling anchor changed upstream.')
p.write_text(s.replace(old, new, 1))

p = Path(sys.argv[2])
s = p.read_text()
old = '<div wire:poll.3000ms="refreshDeployments" @class(['
new = '<div @if ($hasActiveDeployments) wire:poll.5000ms="refreshDeployments" @else wire:poll.60000ms="refreshDeployments" @endif @class(['
if s.count(old) != 1:
    raise SystemExit('Active deployment polling anchor changed upstream.')
p.write_text(s.replace(old, new, 1))
PY

for file in \
    app/Livewire/Dashboard.php \
    app/Livewire/LocalServerVitals.php \
    app/Livewire/Project/Index.php \
    app/Support/ProjectDomainAggregator.php \
    app/Support/ProjectStatusAggregator.php; do
    if command -v php >/dev/null; then
        php -l "$file" >/dev/null
    fi
done

grep -q "value: 'running'" resources/views/livewire/project/index.blade.php
grep -q 'project.domains' resources/views/livewire/project/index.blade.php
grep -q '<livewire:local-server-vitals' resources/views/layouts/app.blade.php
grep -q '<x-local-magnifier' resources/views/layouts/app.blade.php
grep -q 'wire:poll.15s="refreshVitals"' resources/views/livewire/local-server-vitals.blade.php
grep -q 'wire:poll.60000ms' resources/views/livewire/deployments-indicator.blade.php
grep -q 'wire:poll.60000ms="refreshDeployments"' resources/views/livewire/dashboard/active-deployments.blade.php
grep -q "'applications.build_pack as build_pack'" app/Support/ProjectDomainAggregator.php
grep -q "if (\$application->build_pack === 'dockercompose')" app/Support/ProjectDomainAggregator.php
grep -Fq '$domainString = $entry['"'"'domain'"'"'] ?? null;' app/Support/ProjectDomainAggregator.php
! grep -q 'addTraefikHostRules' app/Support/ProjectDomainAggregator.php
! grep -q 'array_walk_recursive' app/Support/ProjectDomainAggregator.php

git add -A
expected="$(cat <<'EOF'
app/Livewire/Dashboard.php
app/Livewire/LocalServerVitals.php
app/Livewire/Project/Index.php
app/Support/ProjectDomainAggregator.php
app/Support/ProjectStatusAggregator.php
resources/views/components/local-magnifier.blade.php
resources/views/layouts/app.blade.php
resources/views/livewire/dashboard.blade.php
resources/views/livewire/dashboard/active-deployments.blade.php
resources/views/livewire/deployments-indicator.blade.php
resources/views/livewire/local-server-vitals.blade.php
resources/views/livewire/project/index.blade.php
EOF
)"
actual="$(git diff --cached --name-only | sort)"
[[ "$actual" == "$(printf '%s\n' "$expected" | sort)" ]] || {
    echo 'Unexpected file set:' >&2
    printf '%s\n' "$actual" >&2
    exit 51
}

git diff --cached --check
printf 'Community pack build OK: Coolify %s (%s)\n' "$UPSTREAM_TAG" "$UPSTREAM_SHA"
printf 'Output: %s\n' "$OUT"
