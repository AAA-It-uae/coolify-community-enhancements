#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPSTREAM_SHA='70c1bcb1381de7d42fd290e6cd50bf9a5bcf714d'
PATCH_SHA='25018ac2eae5a785ea298c57d2a4d6916db3e51fd623aae83bcaeac3834decb7'
OUT="${1:-$SCRIPT_DIR/.build/coolify-v4.5.3-v2}"

test ! -e "$OUT" || { echo "Build destination exists: $OUT" >&2; exit 50; }
command -v git >/dev/null
command -v sha256sum >/dev/null
printf '%s  %s\n' "$PATCH_SHA" "$SCRIPT_DIR/patch-v4.5.3.diff" | sha256sum -c - >/dev/null
mkdir -p "$(dirname "$OUT")"
if [[ -n "${UPSTREAM_SOURCE:-}" ]]; then
    git clone --quiet --no-checkout "$UPSTREAM_SOURCE" "$OUT"
    git -C "$OUT" checkout --quiet "$UPSTREAM_SHA"
else
    git clone --quiet --depth 1 --branch v4.5.3 https://github.com/coollabsio/coolify.git "$OUT"
fi
cd "$OUT"
test "$(git rev-parse HEAD)" = "$UPSTREAM_SHA" || { echo 'Official source tag changed' >&2; exit 51; }
git apply --index --check "$SCRIPT_DIR/patch-v4.5.3.diff"
git apply --index "$SCRIPT_DIR/patch-v4.5.3.diff"

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
test "$actual" = "$(printf '%s\n' "$expected" | sort)" || { echo 'Unexpected patched file set' >&2; exit 52; }
git diff --cached --check
for path in app/Livewire/Dashboard.php app/Livewire/LocalServerVitals.php app/Livewire/Project/Index.php app/Support/ProjectDomainAggregator.php app/Support/ProjectStatusAggregator.php; do
    if command -v php >/dev/null; then php -l "$path" >/dev/null; fi
done
grep -Fq 'use App\Models\TeamInvitation;' app/Livewire/Dashboard.php
grep -q '<livewire:local-server-vitals' resources/views/layouts/app.blade.php
grep -q 'project.domains' resources/views/livewire/project/index.blade.php
printf 'COMMUNITY_PACK_453_V2_BUILD_OK upstream=%s patch=%s\n' "$UPSTREAM_SHA" "$PATCH_SHA"
