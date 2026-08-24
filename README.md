# Coolify Community Enhancements

Tested, version-specific enhancements for self-hosted Coolify installations.

Maintained by [@mtalavi](https://github.com/mtalavi).

> [!IMPORTANT]
> These are community-maintained modifications, not official Coolify features. They patch files inside the running Coolify container and can be replaced by a future Coolify update. Every installer is designed around prechecks, backup, validation, and rollback.

## Enhancements

### 1. Dashboard Observability

Adds operational information directly to the Coolify interface:

- live CPU usage and core count
- live RAM usage and capacity
- 1-minute server load
- project-level status badges: `Running`, `Starting`, `Unhealthy`, `Stopped`, `Empty`
- no custom HTTP telemetry endpoint
- Livewire-based refresh

See [`dashboard-observability/`](dashboard-observability/).

### 2. Dashboard Performance Tuning

Reduces avoidable background work in the dashboard:

- short-lived cache for aggregate project status
- server-vitals polling from 2s to 5s
- deployment indicator polling from 3s to 10s
- active-deployments polling from 3s to 10s

On one real Coolify 4.3.10 installation with 22 projects, measured median component times changed as follows after cache prewarming:

| Path | Before | After |
| --- | ---: | ---: |
| Dashboard mount | 182.67 ms | 18.85 ms |
| Projects mount | 227.31 ms | 22.77 ms |
| Project status aggregation | 315.76 ms | 4.10 ms |

These measurements are from one installation and are evidence of the tested case, not a universal benchmark.

See [`dashboard-performance/`](dashboard-performance/).

### 3. Project Dashboard Plus

Extends the Projects view with information useful during day-to-day operations:

- `Running first` sorting
- persisted sort preference
- status column in table view
- clickable project domains in grid and table views
- domains included in search
- responsive horizontal table scrolling
- server-load gauge relative to CPU core count
- short-lived domain aggregation cache

See [`project-dashboard-plus/`](project-dashboard-plus/).

## Tested Environment

The initial implementation was validated on:

- Coolify `4.3.10`
- standard Docker-based Coolify installation
- healthy `coolify`, database, Redis, realtime, sentinel and proxy containers

Each enhancement checks its expected source anchors before modifying files. If the installed Coolify source no longer matches the tested layout, the installer should stop instead of applying an unknown patch.

## Safety Model

The scripts follow the same basic sequence:

1. verify the Coolify container and required source files
2. create a timestamped backup
3. patch temporary copies first
4. copy the validated result into the container
5. run PHP / Blade validation where applicable
6. clear and rebuild framework caches
7. restart only the Coolify application container when required
8. wait for healthy state
9. rollback automatically if the operation fails

## Why This Repository Exists

These changes started as operational improvements used on a real self-hosted Coolify server. The repository publishes the working approach so other operators can inspect, test, adapt, or improve it.

Where an enhancement is useful beyond a local installation, the goal is to discuss the product direction with the Coolify community and, when aligned with the maintainers, contribute a native upstream implementation.

## Compatibility

Do not assume compatibility with newer Coolify versions. Check the README inside each enhancement before running it.

If Coolify changes the relevant Blade, Livewire, model, or support files, prefer adapting the patch to the new upstream source rather than forcing it.

## Contributing

Focused reports and improvements are welcome. Include:

- Coolify version
- what you changed
- how you tested it
- before/after behavior
- relevant logs without credentials or private hostnames

## License

MIT. See [`LICENSE`](LICENSE).
