# WORDPRESS

**About:** Blogging Platform. \
**Default Subdomain:** `blog.domain.tld`

## Setup

- Copy `template_env` to `.env` and edit as appropriate.
- Start container.

## Reverse Proxy

`Caddyfile`
```
########## EXAMPLE
blog.{$DOMAIN} {
    reverse_proxy wordpress:80
}
```

## Backup and Restore

### Backup

- Include this entire directory in backups.

### Restore

- Replace this entire directory from backup.
- Launch container.

## Resources

- https://github.com/docker/awesome-compose/tree/master/wordpress-mysql
- https://hub.docker.com/_/wordpress
- https://github.com/docker-library/wordpress/issues/30#issuecomment-797180870
