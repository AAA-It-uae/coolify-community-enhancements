# Dashboard Observability

Adds live host resource information and project health directly to the Coolify UI.

## Features

- CPU core count and usage
- RAM used / total / percentage
- 1-minute server load relative to CPU core count
- project statuses: `Running`, `Starting`, `Unhealthy`, `Stopped`, `Empty`
- status badges on Dashboard project cards
- status badges on Projects grid cards
- 5-second status cache to avoid repeatedly hydrating every resource relation
- no custom HTTP telemetry route

## Tested Environment

Initial target: Coolify `4.3.10`.

The implementation was exercised on a real Docker-based installation and validated before and after restarting the Coolify application container.

## Install

```bash
sudo bash install.sh
```

The installer:

1. checks that the Coolify container is healthy
2. verifies the tested Coolify image version
3. backs up every modified file
4. creates the new Livewire and support components
5. patches only known source anchors
6. runs PHP syntax checks and Blade view compilation
7. restarts only the Coolify application container
8. waits for healthy state
9. rolls back automatically on failure

Backups are stored under `/root/coolify-community-backups/`.

## Persistence

This is an external container patch. A Coolify upgrade can replace it. Re-check compatibility after every Coolify update.

## Upstream Direction

The external patch is useful as a working proof of concept. A native Coolify implementation should be adapted to current upstream architecture instead of copying the installer into the product.
