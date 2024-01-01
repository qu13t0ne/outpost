# FLAME - Startpage

**About:** "Flame is self-hosted startpage for your server." \
**Default Subdomain:** `domain.tld`, `www.domain.tld` \

## Setup

- Create `.env` from `template-env`
- Run the container

### Reverse Proxy

`Caddyfile`
```
########## FLAME HOMEPAGE
{$DOMAIN},www.{$DOMAIN} {
    reverse_proxy <container_name>:<port>
}
```

## Backup

- Include this entire directory in backups.

### Restore

- Replace this entire directory from backup.
- Launch container.

## Resources

- https://github.com/pawelmalak/flame
