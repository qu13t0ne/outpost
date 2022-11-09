# Nextcloud

**About:** The flexible open source file synchronization and sharing solution. \
**Default Subdomain:** `nextcloud.domain.tld`

## Info

This Nextcloud installation includes the following components:
- Nextcloud Apache instance (combined app and web server)
- Full-feature Dockerfile from the `nextcloud/docker` repo examples section, including SMB support, image preview generation, and integrated cron
- MariaDB
- Redis caching

## Setup

### Initial
- Copy `template-env` to `.env`
- Edit `.env` to change FQDN, passwords, data directories, and email config
- Run the containers
- Access the service from your browser at the defined subdomain
- Create the initial admin user

## Backup

- Four directories need to be included in backups:
    - `APPDATA` Application data (Default: `/srv/nextcloud/appdata`)
    - `USERDATA` User account files (Default: `/srv/nextcloud/users`)
    - `DBDATA` The database (Default: `/srv/nextcloud/db`)
    - `SHARED` Directories shared by other apps (Default: `/srv/SHARED`)

## Resources

- https://github.com/nextcloud/docker
- https://github.com/nextcloud/docker/tree/master/.examples
- https://docs.nextcloud.com/server/stable/admin_manual/office/example-docker.html
