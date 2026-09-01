#!/usr/bin/env bash
set -Eeuo pipefail

EXPECTED_VERSION='4.3.14'
EXPECTED_SHA='51a8a97d876cdbd6beeced554dbb8b4bec5a3bb4'
CONTAINER="${COOLIFY_CONTAINER:-coolify}"
ROOT='/var/www/html'
PACK_REPO='https://github.com/AAA-It-uae/coolify-community-enhancements.git'
PACK_REF="${PACK_REF:-main}"
TMP="$(mktemp -d)"
PACK_DIR="$TMP/pack"
BUILD_DIR="$TMP/build"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="/data/coolify/backups/community-pack-v${EXPECTED_VERSION}-${STAMP}"
WRITE_STARTED=0
ROLLED_BACK=0

existing_files=(
    app/Livewire/Dashboard.php
    app/Livewire/Project/Index.php
    resources/views/layouts/app.blade.php
    resources/views/livewire/dashboard.blade.php
    resources/views/livewire/dashboard/active-deployments.blade.php
    resources/views/livewire/deployments-indicator.blade.php
    resources/views/livewire/project/index.blade.php
)
new_files=(
    app/Livewire/LocalServerVitals.php
    app/Support/ProjectDomainAggregator.php
    app/Support/ProjectStatusAggregator.php
    resources/views/components/local-magnifier.blade.php
    resources/views/livewire/local-server-vitals.blade.php
)
all_files=("${existing_files[@]}" "${new_files[@]}")

cleanup() { rm -rf "$TMP"; }
wait_healthy() {
    for _ in $(seq 1 60); do
        status="$(docker inspect -f '{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null || true)"
        [[ "$status" == 'healthy' ]] && return 0
        sleep 2
    done
    return 1
}
rollback() {
    [[ "$WRITE_STARTED" == 1 && "$ROLLED_BACK" == 0 ]] || return 0
    ROLLED_BACK=1
    echo 'Install failed. Restoring the previous Coolify files...' >&2
    for rel in "${existing_files[@]}"; do
        docker cp "$BACKUP_DIR/files/$rel" "$CONTAINER:$ROOT/$rel" >/dev/null 2>&1 || true
    done
    for rel in "${new_files[@]}"; do
        docker exec "$CONTAINER" rm -f "$ROOT/$rel" >/dev/null 2>&1 || true
    done
    docker exec "$CONTAINER" php artisan optimize:clear >/dev/null 2>&1 || true
    docker exec "$CONTAINER" php artisan view:cache >/dev/null 2>&1 || true
    docker restart "$CONTAINER" >/dev/null 2>&1 || true
    wait_healthy || true
    echo "Rollback finished. Backup: $BACKUP_DIR" >&2
}
trap 'rc=$?; (( rc == 0 )) || rollback; cleanup; exit $rc' EXIT

[[ "$EUID" -eq 0 ]] || { echo 'Run this installer as root (or with sudo).' >&2; exit 40; }
for cmd in docker git python3 curl; do command -v "$cmd" >/dev/null || { echo "Missing command: $cmd" >&2; exit 41; }; done

docker inspect "$CONTAINER" >/dev/null 2>&1 || { echo "Coolify container '$CONTAINER' was not found." >&2; exit 42; }
IMAGE="$(docker inspect -f '{{.Config.Image}}' "$CONTAINER")"
case "$IMAGE" in
    "coollabsio/coolify:$EXPECTED_VERSION"|"docker.io/coollabsio/coolify:$EXPECTED_VERSION"|"ghcr.io/coollabsio/coolify:$EXPECTED_VERSION") ;;
    *) echo "This pack is only for Coolify $EXPECTED_VERSION. Found: $IMAGE" >&2; exit 43 ;;
esac
[[ "$(docker inspect -f '{{.State.Health.Status}}' "$CONTAINER")" == 'healthy' ]] || { echo 'Coolify is not healthy. Aborting.' >&2; exit 44; }

if docker exec "$CONTAINER" grep -q '<livewire:local-server-vitals' "$ROOT/resources/views/layouts/app.blade.php" 2>/dev/null; then
    echo "Community pack is already installed on Coolify $EXPECTED_VERSION."
    exit 0
fi

for rel in "${new_files[@]}"; do
    if docker exec "$CONTAINER" test -e "$ROOT/$rel"; then
        echo "Custom file already exists and is not owned by this installer: $rel" >&2
        exit 45
    fi
done

git clone --quiet --depth 1 --branch "$PACK_REF" "$PACK_REPO" "$PACK_DIR"
bash "$PACK_DIR/community-pack/build.sh" "$BUILD_DIR"
[[ "$(git -C "$BUILD_DIR" rev-parse HEAD)" == "$EXPECTED_SHA" ]] || { echo 'Unexpected upstream source commit.' >&2; exit 46; }

mkdir -p "$BACKUP_DIR/files"
for rel in "${existing_files[@]}"; do
    mkdir -p "$TMP/current/$(dirname "$rel")" "$TMP/base/$(dirname "$rel")" "$BACKUP_DIR/files/$(dirname "$rel")"
    docker cp "$CONTAINER:$ROOT/$rel" "$TMP/current/$rel" >/dev/null
    git -C "$BUILD_DIR" show "HEAD:$rel" > "$TMP/base/$rel"
    cmp -s "$TMP/current/$rel" "$TMP/base/$rel" || {
        echo "Coolify source differs from the official $EXPECTED_VERSION file: $rel" >&2
        echo 'Nothing was changed.' >&2
        exit 47
    }
    cp "$TMP/current/$rel" "$BACKUP_DIR/files/$rel"
done

printf 'version=%s\nimage=%s\nupstream_sha=%s\ncreated=%s\n' \
    "$EXPECTED_VERSION" "$IMAGE" "$EXPECTED_SHA" "$(date -Is)" > "$BACKUP_DIR/manifest.txt"

WRITE_STARTED=1
for rel in "${all_files[@]}"; do
    docker exec "$CONTAINER" mkdir -p "$ROOT/$(dirname "$rel")"
    docker cp "$BUILD_DIR/$rel" "$CONTAINER:$ROOT/$rel" >/dev/null
done

for rel in \
    app/Livewire/Dashboard.php \
    app/Livewire/LocalServerVitals.php \
    app/Livewire/Project/Index.php \
    app/Support/ProjectDomainAggregator.php \
    app/Support/ProjectStatusAggregator.php; do
    docker exec "$CONTAINER" php -l "$ROOT/$rel" >/dev/null
done

docker exec "$CONTAINER" php artisan optimize:clear >/dev/null
docker exec "$CONTAINER" php artisan view:cache >/dev/null
docker restart "$CONTAINER" >/dev/null
wait_healthy || { echo 'Coolify did not return to healthy state.' >&2; exit 48; }

docker exec "$CONTAINER" grep -q '<livewire:local-server-vitals' "$ROOT/resources/views/layouts/app.blade.php"
docker exec "$CONTAINER" grep -q '<x-local-magnifier' "$ROOT/resources/views/layouts/app.blade.php"
docker exec "$CONTAINER" grep -q "value: 'running'" "$ROOT/resources/views/livewire/project/index.blade.php"
docker exec "$CONTAINER" grep -q 'project.domains' "$ROOT/resources/views/livewire/project/index.blade.php"
docker exec "$CONTAINER" grep -q 'addTraefikHostRules' "$ROOT/app/Support/ProjectDomainAggregator.php"
docker exec "$CONTAINER" grep -q 'wire:poll.15s="refreshVitals"' "$ROOT/resources/views/livewire/local-server-vitals.blade.php"
docker exec "$CONTAINER" grep -q 'wire:poll.60000ms' "$ROOT/resources/views/livewire/deployments-indicator.blade.php"
docker exec "$CONTAINER" grep -q 'wire:poll.60000ms="refreshDeployments"' "$ROOT/resources/views/livewire/dashboard/active-deployments.blade.php"

WRITE_STARTED=0
echo "Community pack installed successfully on Coolify $EXPECTED_VERSION."
echo "Backup: $BACKUP_DIR"
echo 'Official Coolify updates replace container-level customizations. Reinstall only after this pack explicitly supports the new version.'
