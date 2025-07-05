# SERVICE_NAME

- **About:** TBD.
- **Default Port:** TBD

## Setup

- Copy `template_env` to `.env` and edit as appropriate.
- Start container.

## Reverse Proxy

`Caddyfile`
```
########## EXAMPLE
example.domain.tld {
    reverse_proxy <host_server>:<port>
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
