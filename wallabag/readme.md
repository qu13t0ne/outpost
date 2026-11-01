# wallabag

- **About:** "A self hostable application for saving web pages, freely."
- **Default Port:** 8280

## Setup

- Run `just init` to create `$OUTPOST_CONFIG_DIR/` from `config.example/`, then edit
  `wallabag/compose.env` (its `PORT`, database credentials, `DATADIR`, and mail; `BIND_ADDR` is
  shared in `outpost.env`).
- Start the container with `just up wallabag`.

## Reverse Proxy

`Caddyfile`
```
########## WALLABAG
wallabag.domain.tld {
    reverse_proxy <server_ip>:8280
}
```

## Backup

Include this directory in backups.

## Resources

- https://wallabag.org/
- https://github.com/wallabag/wallabag
- https://hub.docker.com/r/wallabag/wallabag/
