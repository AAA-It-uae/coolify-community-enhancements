# Coolify community dashboard pack for 4.4.7

This version-specific port adds project status/domain cards, running-first sorting, and CPU/RAM/disk/load vitals to **Coolify 4.4.7**. It preserves the upstream `TeamInvitation` import required by the authenticated dashboard. The original `community-pack/` for 4.3.23 remains unchanged.

The installer checks the exact 4.4.7 image and upstream commit `86c21c0d5babfa8c7d65a9c27e5863c629a89c7c`, compares untouched Coolify files to that source, backs up every file it writes, validates PHP/Blade, restarts only the Coolify app, and restores the prior files if validation fails. It also recognizes the earlier Iran vitals-only layout block, verifies that removing that block exactly matches the official layout, and keeps the prior vitals files in its backup. Use `build.sh` to preflight the source patch. The exact tag `coolify-4.4.7-pack-v2` is the default install ref.

Install on a healthy instance only after an instance backup and with no active deployment. Keep the generated `/data/coolify/backups/community-pack-v4.4.7-*` backup for rollback. A later official Coolify container recreation removes these container-layer modifications; re-evaluate compatibility before reinstalling on any later Coolify version.

This is a community customization, not part of official Coolify.
