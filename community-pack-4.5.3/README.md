# Coolify dashboard pack for 4.5.3

Adds CPU, RAM, disk and load to the top bar, plus project status and clickable domains on Dashboard and Projects cards. On narrower screens, a server-resources button opens the same metrics without crowding the top bar. Running projects sort first. The package also includes the magnifier and reduces deployment polling while idle.

Target: Coolify `v4.5.3`, source commit `70c1bcb1381de7d42fd290e6cd50bf9a5bcf714d`.

The installer checks the exact version and untouched upstream files, saves every file it replaces, validates PHP and Blade, restarts the Coolify app container, waits for health, and restores the prior files on failure. Run it only after a current control-plane backup and with no active deployment.

```bash
curl -fsSL https://raw.githubusercontent.com/AAA-It-uae/coolify-community-enhancements/coolify-4.5.3-pack-v3/community-pack-4.5.3/install-v3.sh | sudo bash
```

To check compatibility without writing to the container, download the script and run it with `PACK_PREFLIGHT_ONLY=1`. The v3 installer verifies every current pack file against the pinned v2 hashes before upgrading an existing installation.

The change lives in the Coolify container layer. A future Coolify update recreates that container; port and test this pack against the new version before installing it again.
