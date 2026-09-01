# Dashboard domain source of truth

Project-card domains must match Coolify's own Domains UI.

- Regular applications: use `applications.fqdn`.
- Docker Compose applications: ignore the legacy/generated application `fqdn` and read only each `docker_compose_domains[service].domain` value.
- Service applications: use `service_applications.fqdn`.
- Do not infer public domains from Traefik rules, container names, internal hostnames, or arbitrary values inside the Compose domains JSON.

The dashboard cache is intentionally short-lived so a refreshed dashboard follows domain changes quickly without adding repeated heavy work.
