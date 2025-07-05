# MongoDB (NoSQL DB) + Mongo-Express Web GUI

**About:** Document-oriented Database Platform plus a Web-based admin interface. \
**Default Subdomain:** `mongo.domain.tld`

## Setup

- Copy `template_env` to `.env` and edit as appropriate.
- Start container.

## Reverse Proxy

`Caddyfile`
```
########## MONGODB-EXPRESS
mongo.{$DOMAIN} {
    reverse_proxy mongodb-gui:8081
}
```

## Backup and Restore

### Backup

- Include this entire directory in backups.

### Restore

- Replace this entire directory from backup.
- Launch container.

## Resources

- https://www.mongodb.com/
- https://github.com/mongo-express/mongo-express