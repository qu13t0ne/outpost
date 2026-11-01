# SERVICE_NAME

- **About:** TBD.
- **Default Port:** TBD

## Setup

- Run `just init` to create `$OUTPOST_CONFIG_DIR/`, then create this service's
  `config.example/<service>/compose.env` from `.env.example` and edit it as appropriate.
- Start the container with `just up <service>`.

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
