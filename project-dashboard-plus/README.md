# Project Dashboard Plus

A focused set of improvements for making the Coolify Projects view useful as an operational dashboard rather than only a navigation page.

## Features

- **Running-first sorting** so active workloads are surfaced before inactive projects.
- **Persisted sort preference** so the selected ordering survives page reloads.
- **Project status at a glance** with `Running`, `Starting`, `Unhealthy`, `Stopped` and `Empty` states.
- **Clickable active domains** directly on project cards.
- **Domain-aware search** so projects can also be found by their exposed hostnames.
- Improved table/grid usability for larger installations.

## Screenshots

### Running-first sorting

![Running first sorting](../assets/screenshots/running-first-sort.webp)

### Running project with active domain

![Running project and clickable domain](../assets/screenshots/project-running-domain.webp)

### Stopped project state

![Stopped project state](../assets/screenshots/project-stopped-status.webp)

## Why

When operating many projects, the important questions are usually operational:

1. What is running now?
2. What is stopped or unhealthy?
3. Which domain belongs to this project?
4. Can I reach that domain immediately?

Surfacing that information on the card removes repeated navigation into individual projects.

## Implementation direction

The tested prototype extends the existing Coolify project index and derives state from existing Coolify resource models. Domain information is aggregated from application and service data, normalized, cached briefly and exposed as clickable chips.

For upstream contribution, this should be implemented natively against the current Coolify source rather than treating an external container patch as the desired final architecture.

## Compatibility

Initial prototype tested on Coolify `4.3.10`. Treat the implementation as version-specific until validated against later releases.
