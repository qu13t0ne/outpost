# Adminer (Database Management)

**About:** Database management GUI. \
**Default Subdomain:** `adminer.domain.tld`

## Setup

- Copy `template_env` to `.env` and edit as appropriate.
- Start container.

## Reverse Proxy

`Caddyfile`
```
########## ADMINER
adminer.{$DOMAIN1} {
	reverse_proxy adminer:8080
}
```

## Backup and Restore

The only files of value are the `.env` file and possibly the `docker-compose.yml` file, if customized.

## Resources

- https://www.adminer.org/