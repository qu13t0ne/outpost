# Syncthing

- **About:** "Open Source Continuous File Synchronization" — syncs files between devices directly, with no cloud intermediary.
- **Default Port:** 8384 (web UI), 22000 (sync), 21027 (local discovery)

## Setup

- Copy `template_env` to `.env` and edit as appropriate.
  - Set `PUID` and `PGID` by running `id -u` and `id -g` on the host.
  - **Exception:** if syncing into the Nextcloud data directory, see the [Nextcloud section](#nextcloud-aio-data-directory) below for required PUID/PGID values.
  - Set `TZ` to your timezone.
- Start the container.
- Open the Syncthing UI via the reverse proxy URL and complete initial configuration.

## Reverse Proxy

Syncthing performs a CSRF host-header check and will reject requests where the `Host` header does not match its expected value. The `header_up` directive is **required** to pass that check when proxying through Caddy.

**Caddy on the same host** (default): Caddy reaches Syncthing by container name over the shared `outpost` Docker network. Port 8384 does not need to be published.

`Caddyfile`

```
########## SYNCTHING
syncthing.domain.tld {
    import use_tls
    import errorHandling

    reverse_proxy syncthing:8384 {
        header_up Host {upstream_hostport}
    }
}
```

**Caddy on a separate host**: uncomment `- 8384:8384` in `docker-compose.yml`, then restrict port 8384 on the host firewall to the Caddy host's IP (do not expose it to the open internet). Replace `syncthing:8384` in the Caddyfile with `<syncthing-host-ip>:8384`. The `outpost` network block in the compose file is not needed and can be removed in this case.

```
########## SYNCTHING (remote host)
syncthing.domain.tld {
    import use_tls
    import errorHandling

    reverse_proxy <syncthing-host-ip>:8384 {
        header_up Host {upstream_hostport}
    }
}
```

## Mounting Host Folders

Sync folders are added as bind mounts in `docker-compose.yml` and then registered as folders inside the Syncthing UI. The container path (right side of the `:`) is what you enter in the Syncthing UI when adding a folder.

### Generic Host Directory

Add a bind mount in `docker-compose.yml` under `volumes:`:

```yaml
volumes:
  - $CONFIG_PATH:/config
  - /path/on/host:/data/foldername
```

Then in the Syncthing UI, add the folder path `/data/foldername`.

`PUID`/`PGID` should match the owner of the host directory so Syncthing can read and write files.

---

### Nextcloud AIO Data Directory

Nextcloud AIO runs its containers with UID/GID `33` (`www-data`). To allow Syncthing to write into the Nextcloud data directory, **Syncthing must also run as UID/GID 33**.

In `.env`:

```
PUID=33
PGID=33
```

In `docker-compose.yml`, uncomment (or add) the Nextcloud volume line, setting `NEXTCLOUD_DATADIR` to match the value in the Nextcloud service's `.env`:

```yaml
volumes:
  - $CONFIG_PATH:/config
  - $NEXTCLOUD_DATADIR/ncdata:/data/nextcloud
```

> The full path to a given user's files inside the container is:
> `/data/nextcloud/<username>/files/`

In the Syncthing UI, add the folder at `/data/nextcloud/<username>/files/` (or a subdirectory within it).

#### Mixing Nextcloud and Other Sync Folders (UID Conflict)

Running Syncthing at `PUID=33` means it runs as `www-data` inside the container. If you also want to sync host directories owned by a different user (e.g. UID 1000), Syncthing will not have write access to those directories.

**Option A — Two Syncthing instances (recommended for mixed workloads)**

Add a second service in `docker-compose.yml` with a separate `CONFIG_PATH`, `PUID`/`PGID` matching the other directories' owner, and a different internal port mapping. Proxy each instance to its own subdomain.

**Option B — POSIX ACLs on the non-Nextcloud directories**

Keep one instance at `PUID=33` and grant UID 33 write access to the other host directories without changing their ownership:

```bash
# Grant access to existing files
sudo setfacl -R -m u:33:rwX /path/on/host
# Apply the same grant to files created in future
sudo setfacl -R -d -m u:33:rwX /path/on/host
```

Run these commands on the host for each non-Nextcloud directory you want to sync.

---

#### Re-indexing Nextcloud After Syncthing Writes

Nextcloud does not automatically detect files added or changed by external processes. After Syncthing writes files, trigger a rescan:

```bash
docker exec nextcloud-aio-nextcloud php occ files:scan --all
```

To automate this, add a cron job on the host:

```
*/15 * * * * docker exec nextcloud-aio-nextcloud php occ files:scan --all
```

Adjust the interval as needed. Run `docker exec nextcloud-aio-nextcloud php occ files:scan --help` for options to scope the scan to a specific user or path.

---

### External NAS / Host Mount (e.g. `/mnt/mynas`)

If the host has an external volume mounted at a path like `/mnt/mynas`, bind-mount it directly:

```yaml
volumes:
  - $CONFIG_PATH:/config
  - /mnt/mynas:/data/mynas
```

Then in the Syncthing UI, add the folder path `/data/mynas` (or a subdirectory).

> The host mount must be active before the Syncthing container starts. If the mount is absent at startup, Docker will create an empty directory at that path instead of using the NAS volume.

---

## Backup and Restore

### Backup

- Include this entire directory in backups.
- The `CONFIG_PATH` directory contains all Syncthing configuration, device certificates, and folder metadata.

### Restore

- Replace this entire directory and the `CONFIG_PATH` directory from backup.
- Launch container.

## Resources

- https://syncthing.net/
- https://docs.syncthing.net/
- https://hub.docker.com/r/linuxserver/syncthing
- https://docs.linuxserver.io/images/docker-syncthing/
