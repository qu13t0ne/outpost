# Dashboard: DASHY

**About:** "A self-hostable personal dashboard built for you. Includes status-checking, widgets, themes, icon packs, a UI editor and tons more!"

## Setup

- Create `.env` from `template-env`
    - Validate UID and GID by running `id -u` and `id -g`
- Run the container

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
- https://github.com/lissy93/dashy
