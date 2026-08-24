# Dashboard Performance Tuning

A conservative, version-specific patch for reducing repeated background work in Coolify's dashboard.

## What it changes

- Adds a 5-second cache around aggregate project-status calculation when `app/Support/LocalProjectStatus.php` is present.
- Changes the live server-vitals refresh interval from 2 seconds to 5 seconds when that component is present.
- Changes the global deployments indicator from 3 seconds to 10 seconds.
- Changes the dashboard active-deployments refresh from 3 seconds to 10 seconds.

The script does not disable navigation features and does not modify application deployments.

## Tested case

Validated on Coolify `4.3.10` with 22 projects.

Measured median component times in that installation:

| Path | Before | After |
| --- | ---: | ---: |
| Dashboard mount | 182.67 ms | 18.85 ms |
| Projects mount | 227.31 ms | 22.77 ms |
| Project status aggregation | 315.76 ms | 4.10 ms |

The first uncached project-status run was about 296 ms; subsequent cached runs were about 3 ms. Results depend on installation size and workload.

## Install

```bash
sudo bash install.sh
```

The script creates a timestamped backup under `/root/coolify-community-backups/` and automatically restores it if validation fails.

## Compatibility

Initial target: Coolify `4.3.10`.

The patch is anchor-based. If the expected upstream source has changed, it exits instead of forcing replacements.
