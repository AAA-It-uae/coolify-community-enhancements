# Dashboard Observability

Adds live host resource information and project health directly to the Coolify UI.

## Features

- CPU core count, used percentage and free percentage
- RAM used / available / total with percentages
- root filesystem disk used / free / total with percentages
- Linux server load averages for 1 / 5 / 15 minutes
- responsive top-bar HUD with progressive disclosure on narrower desktop widths
- project statuses: `Running`, `Starting`, `Unhealthy`, `Stopped`, `Empty`
- status badges on Dashboard project cards
- status badges on Projects grid cards
- 5-second project-status cache to avoid repeatedly hydrating every resource relation
- 15-second Livewire refresh for host vitals
- no custom HTTP telemetry route

## Visual

<p align="center">
  <img src="../assets/screenshots/server-vitals-cpu-ram-disk.png" alt="Coolify live CPU, RAM and disk indicators" width="100%">
</p>

The HUD uses red for used capacity, green for free/available capacity, and gray for totals. Disk values are read from the root filesystem (`/`).

## Validation evidence

The disk addition was exercised on a real Coolify `4.3.10` installation with backup and rollback protection. The post-restart component reported:

- total: `95.8 GiB`
- used: `41.1 GiB` (`42.9%`)
- free: `54.7 GiB` (`57.1%`)

The same host reported approximately `96G / 42G / 55G` through `df`, Coolify returned healthy after restart, and no unhealthy containers were present.

These numbers document one tested installation; they are not universal capacity figures.

## Tested Environment

Initial target: Coolify `4.3.10`.

The implementation was exercised on a real Docker-based installation and validated before and after restarting only the Coolify application container.

## Install

```bash
sudo bash install.sh
```

The installer:

1. checks that the Coolify container is healthy
2. verifies the tested Coolify image version
3. backs up every modified file
4. creates the Livewire and project-status support components
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
