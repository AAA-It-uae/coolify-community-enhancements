<p align="center">
  <img src="assets/hero/coolify-community-hero.svg" alt="Coolify Community Enhancements" width="100%">
</p>

<p align="center">
  <a href="https://github.com/coollabsio/coolify/releases/tag/v4.3.15"><img src="https://img.shields.io/badge/Coolify-4.3.15%20tested-7c3aed?style=flat-square" alt="Tested on Coolify 4.3.15"></a>
  <a href="https://github.com/AAA-It-uae/coolify-community-enhancements/actions"><img src="https://img.shields.io/badge/CI-validated-16a34a?style=flat-square" alt="CI validated"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-2563eb?style=flat-square" alt="MIT License"></a>
</p>

# A more useful Coolify dashboard

I manage enough projects that the stock dashboard started making me open too many pages for basic answers: **what is running, where is it, and does the server look healthy?**

This repo is my small community pack for fixing that.

The current pack is built specifically for **Coolify 4.3.15** and adds:

- project status directly on cards
- active clickable domains
- `Running first` sorting
- domain-aware project search
- CPU, RAM, disk and load in the desktop top bar
- a compact magnifier
- less aggressive background polling

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/AAA-It-uae/coolify-community-enhancements/main/community-pack/install.sh | sudo bash
```

The installer is deliberately strict. It checks the exact Coolify version and source files first, creates a backup, validates the modified files, waits for Coolify to become healthy again, and rolls back if something fails.

[Read the short install notes](community-pack/README.md)

## What it looks like

### Server health without leaving the dashboard

![Live CPU, RAM and disk indicators](assets/screenshots/server-vitals-cpu-ram-disk.png)

### Project status and the domain you actually want to open

<table>
<tr>
<td width="50%"><img src="assets/screenshots/project-running-domain.webp" alt="Running project with active domain"></td>
<td width="50%"><img src="assets/screenshots/project-stopped-status.webp" alt="Stopped project status"></td>
</tr>
</table>

### Running projects first

![Running-first sorting](assets/screenshots/running-first-sort.webp)

### Optional magnifier

![Interactive magnifier](assets/screenshots/interactive-magnifier.png)

## Why the polling changes are here

The dashboard should feel alive without constantly doing work when nothing is happening. The pack uses a 15-second host-vitals refresh and moves deployment polling to **5 seconds while active** and **60 seconds while idle**.

Earlier testing on one 22-project Coolify installation also showed how much repeated status work could cost. After short-lived status caching, measured median component times changed from 182.67 ms to 18.85 ms on Dashboard mount, 227.31 ms to 22.77 ms on Projects mount, and 315.76 ms to 4.10 ms for project-status aggregation. Those numbers are evidence from one installation, not a universal benchmark.

## Compatibility and safety

Current target: `v4.3.15`  
Official source commit: `b8866b87e8e855e041c21330352ca615521afed3`

This is a community-maintained modification, not an official Coolify feature. Coolify updates replace container-level customizations, so the installer refuses versions it has not been adapted and validated against.

Older implementation notes are kept in:

- [`dashboard-observability/`](dashboard-observability/)
- [`project-dashboard-plus/`](project-dashboard-plus/)
- [`interactive-magnifier/`](interactive-magnifier/)
- [`dashboard-performance/`](dashboard-performance/)

## Upstream history

The ideas were discussed with the Coolify community and also submitted as native upstream changes:

- [Dashboard proposal #11483](https://github.com/coollabsio/coolify/discussions/11483)
- [Performance proposal #11484](https://github.com/coollabsio/coolify/discussions/11484)
- [UI feedback thread #11195](https://github.com/coollabsio/coolify/discussions/11195)
- [Host vitals PR #11517](https://github.com/coollabsio/coolify/pull/11517)
- [Project operational context PR #11520](https://github.com/coollabsio/coolify/pull/11520)

Both upstream PRs were fully tested and later closed for now because of long-term maintainability and product-direction considerations. The implementations stay here as a community option and as a reference if the dashboard direction changes later.

## License

MIT. See [`LICENSE`](LICENSE).
