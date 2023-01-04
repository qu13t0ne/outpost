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

### Database
Database backups are performed through the `docker-db-backup` container. The container performs scheduled database backups, saves them to a `APPDATA/db_backups`, generates a log file with backup times and checksums, and prunes old backups. The default is to perform nightly backups and retain them for 7 days.

### Data Directories
- Four directories need to be included in backups:
    - `APPDATA/ncdata` Application data (Default: `/srv/nextcloud/ncdata`)
    - `APPDATA/db_backups` The database backups directory (Default: `/srv/nextcloud/db_backups`)
    - `USERDATA` User account files (Default: `/srv/nextcloud/users`)
    - `SHARED` Directories shared by other apps (Default: `/srv/SHARED`)
        - *Unless backup is handled by another system*

## NFS Considerations

- NFS shares mounted to the host can be used for `SHARED` directories.
- To avoid file system permission & ownership issues, `APPDATA` (including the database) and `USERDATA` should be kept on the host file system.
- *I bet there's a better way to deal with these issues and better scale the user data... I just don't know what it is, and this setup works fine for my use case.*

## Recommended Nextcloud Apps

### Security

For better MFA:
- Two-Factor TOTP Provider
- Two-Factor WebAuthn
- Two-Factor Admin Support

For additional security benefits:
- Auditing/Logging
- Brute Force Settings
- Ransomware Protection
- Suspicious Login

### Files and Storage
- Collabora Online - Built-in CODE Server
- External Storage Support
- File Sharing
- Configurable Share Links

### Media
- Photos
- Preview Generator
  - After installing and enabling the app, run `docker exec -u 33 -it nextcloud-app php occ preview:generate-all` to begin generating image previews. (**May take a while, depending on size of image directory!**)
  - On the host system, schedule a cron job to run regularly and pre-generate previews. The following example runs every 10 minutes:
    - Example: `*/10 * * * * docker exec -u 33 -it nextcloud-app php occ preview:pre-generate # nextcloud preview generator app`

## Resources

- https://github.com/nextcloud/docker
- https://github.com/nextcloud/docker/tree/master/.examples
- https://docs.nextcloud.com/server/stable/admin_manual/office/example-docker.html
- https://github.com/tiredofit/docker-db-backup
