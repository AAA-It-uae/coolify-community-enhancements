#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${1:-$SCRIPT_DIR/.build/coolify-v4.5.3-v3}"
RESPONSIVE_PATCH_SHA='88a15ab3e6e9163c7cb286b78353093e5ca7dc756676c2539fdd1d793e010925'

printf '%s  %s\n' "$RESPONSIVE_PATCH_SHA" "$SCRIPT_DIR/responsive-v3.diff" | sha256sum -c - >/dev/null
bash "$SCRIPT_DIR/build-v2.sh" "$OUT"
git -C "$OUT" apply --unidiff-zero --index --check "$SCRIPT_DIR/responsive-v3.diff"
git -C "$OUT" apply --unidiff-zero --index "$SCRIPT_DIR/responsive-v3.diff"
git -C "$OUT" diff --cached --check

grep -Fq 'variant="mobile" key="mobile-vitals"' "$OUT/resources/views/layouts/app.blade.php"
grep -Fq "'hidden lg:flex' => \$variant === 'desktop'" "$OUT/resources/views/livewire/local-server-vitals.blade.php"
grep -Fq "'flex lg:hidden' => \$variant === 'mobile'" "$OUT/resources/views/livewire/local-server-vitals.blade.php"
grep -Fq 'aria-label="Server resources"' "$OUT/resources/views/livewire/local-server-vitals.blade.php"
if command -v php >/dev/null; then php -l "$OUT/app/Livewire/LocalServerVitals.php" >/dev/null; fi

printf 'COMMUNITY_PACK_453_V3_BUILD_OK responsive_patch=%s\n' "$RESPONSIVE_PATCH_SHA"
