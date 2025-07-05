# PHOTOPRISM

**About:** AI-Powered Photos App for the Decentralized Web. \
**Default Subdomain:** `photos.domain.tld`

## Setup

- Copy `template_env` to `.env` and customize, including changing insecure passwords.
- Launch service
- After initial login, trigger library index (first run will take many hours depending on the size of the photos directory and amount of capabilities on the docker host)
- If you are uploading to or otherwise modifying the originals directory through an external tool (e.g., Nextcloud), then configure a cron job to reindex at regular intervals.
```
*/10 * * * * docker exec -it photoprism photoprism index --cleanup # photoprism run index
```
- Configure site in Caddy

## Backup

- The following command creates an index SQL dump of MariaDB and writes it to the `storage` directory.
```
docker exec photoprism photoprism backup -i -f
```
- Consider scheduling daily backups with cron, such as:
```
@daily docker exec photoprism photoprism backup -i -f # photoprism run db backup
```
- Directories to include in external backup tool:
	- The *originals* folder (`$ORIGNIALS_DIR`)
	- The *storage* folder (`$CONFIG_PATH/storage`)
	- The database backup -- should be included in the *storage* directory unless location was explicitly changed
- Ref: https://docs.photoprism.app/user-guide/backups/

## Resources

- https://www.photoprism.app/
- https://github.com/photoprism/photoprism
- https://docs.photoprism.app/
