# Dashboard: DASHY

- **About:** "A self-hostable personal dashboard built for you. Includes status-checking, widgets, themes, icon packs, a UI editor and tons more!"
- **Default Port:** 8080

## Setup

- Run `just init` to create `$OUTPOST_CONFIG_DIR/` from `config.example/`, then edit
  `dashy/compose.env` (its `PORT`, `MY_UID` and `MY_GID`; `BIND_ADDR` is shared in
  `outpost.env`).
    - Validate UID and GID by running `id -u` and `id -g`. See [the configuration model](../docs/config-model.md).
- Start the container with `just up dashy`.

### Reverse Proxy

`Caddyfile`
```
########## DASHBOARD: DASHY
{$DOMAIN} {
    reverse_proxy <host_name>:<port>
}
```

## Backup

- Include this entire directory in backups.

### Restore

- Replace this entire directory from backup.
- Launch container.

## Resources

- https://dashy.to/
- https://dashy.to/docs/deployment#using-docker-compose
- https://github.com/lissy93/dashy
