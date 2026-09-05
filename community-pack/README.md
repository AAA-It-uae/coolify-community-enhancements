# Coolify Community Pack for 4.3.17

I manage enough projects that I got tired of opening extra pages just to answer simple questions: what is running, where is it, and does the server look healthy?

This pack keeps those answers on the dashboard.

It adds:

- project status on Dashboard and Projects cards
- active clickable domains
- `Running first` sorting and domain-aware search
- CPU, RAM, disk and load in the desktop top bar
- a small interface magnifier
- calmer polling: 5s while deployments are active, 60s while idle

## Install

This installer is intentionally pinned to **Coolify 4.3.17**.

```bash
curl -fsSL https://raw.githubusercontent.com/AAA-It-uae/coolify-community-enhancements/main/community-pack/install.sh | sudo bash
```

It refuses unknown versions, checks the running Coolify files against the official 4.3.17 source, creates a backup, validates PHP and Blade, restarts only the Coolify app container, waits for health, and rolls back automatically if the install fails.

## What to expect

![Server vitals](../assets/screenshots/server-vitals-cpu-ram-disk.png)

![Running project and active domain](../assets/screenshots/project-running-domain.webp)

![Stopped project](../assets/screenshots/project-stopped-status.webp)

![Running-first sorting](../assets/screenshots/running-first-sort.webp)

![Magnifier](../assets/screenshots/interactive-magnifier.png)

## Compatibility

Test target: `v4.3.17`  
Official commit: `5ff21103974a30e107ce046190fb478658a214e7`

Coolify updates replace container-level customizations. After an official update, wait until this pack explicitly supports the new version before reinstalling it.

This is a community-maintained modification, not an official Coolify feature.
