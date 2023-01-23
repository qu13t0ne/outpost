# GHOST

**About:** Blog and website platform \
**Default Subdomain:** `ghost.domain.tld`

> Ghost is a free and open source blogging platform written in JavaScript and distributed under the MIT License, designed to simplify the process of online publishing for individual bloggers as well as online publications. ([Wikipedia](http://en.wikipedia.org/wiki/Ghost_%28blogging_platform%29))


## Info

This installation includes the following components:
- Ghost app container
- MySQL database container
- Database backups through `tiredofit/db-backup` container

## Setup

- Copy `template-env` to `.env`
- Edit `env` to change FQDN, passwords, etc.

## Backup

Include the `$APPDATA` directory in backups. This will capture the live app and database directories along with the daily database backup files.

Database backups are performed through the `docker-db-backup` container. The container performs scheduled database backups, saves them to a `$APPDATA/db_backups`, generates a log file with backup times and checksums, and prunes old backups. The default is to perform nightly backups and retain them for 7 days.

## Resources

- https://ghost.org
- https://github.com/TryGhost/Ghost
- https://ghost.org/docs/
- https://github.com/tiredofit/docker-db-backup
