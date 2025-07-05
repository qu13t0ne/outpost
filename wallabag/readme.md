# wallabag

- **About:** "A self hostable application for saving web pages, freely."
- **Default Port:** 8280

## Setup

- Copy `template_env` to `.env`
- Modify `.env` as needed
- Run container

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
