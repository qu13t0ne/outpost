# SERVICE_NAME

**About:** TBD. \
**Default Subdomain:** `example.domain.tld`

## Setup

- Copy `template_env` to `.env` and edit as appropriate.
- Start container.

## Reverse Proxy

`Caddyfile`
```
example.{$DOMAIN} {
    reverse_proxy <container_name>:<port>
}
```

## Backup and Restore

### Backup

- Include this entire directory in backups.

### Restore

- Replace this entire directory from backup.
- Launch container.

## Resources

- Links and references