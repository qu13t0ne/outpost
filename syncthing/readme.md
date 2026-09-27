# Syncthing

- **About:** "Open Source Continuous File Synchronization" - syncs files between devices directly, with no cloud intermediary.
- **Default Port:** 8384 (web UI), 22000 (sync), 21027 (local discovery)

## Setup

- Copy `template_docker-compose.override.yml` to `docker-compose.override.yml` and edit it for this server.
  - No `.env` is used. `docker-compose.yml` holds defaults (container `syncthing`, PUID/PGID 1000, `America/New_York`, config at `./conf`); set only what differs in the override.
  - Set `PUID` and `PGID` to the output of `id -u` and `id -g` for the sync folder owner.
  - **Exception:** if syncing into the Nextcloud data directory, see the [Nextcloud section](#nextcloud-aio-data-directory) below for required PUID/PGID values.
  - Add sync folder mounts (see [Mounting Host Folders](#mounting-host-folders)).
  - Choose the network mode (see [Network Mode](#network-mode)).
  - This file is gitignored, so local paths stay out of the repo.
- Start the container with `docker compose up -d`. Compose merges the override file automatically.
- Open the Syncthing UI via the reverse proxy URL and complete initial configuration.

## Network Mode

| Mode              | Use when                                                        | Access control          |
| ----------------- | --------------------------------------------------------------- | ----------------------- |
| Bridge (default)  | Caddy runs on the same host, on the `outpost` Docker network    | Docker network + ports  |
| Host              | Caddy runs on a different host, or host firewall should govern  | Host firewall           |

Bridge mode needs no override changes. For host mode, uncomment the three host-network lines in
`docker-compose.override.yml`:

```yaml
    network_mode: host
    ports: !reset []
    networks: !reset []
```

`!reset` requires Docker Compose 2.18 or later.

## Reverse Proxy

Syncthing performs a CSRF host-header check and will reject requests where the `Host` header does not match its expected value. The `header_up` directive is **required** to pass that check when proxying through Caddy.

**Bridge mode**: Caddy reaches Syncthing by container name over the shared `outpost` Docker network. Port 8384 does not need to be published.

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

**Host mode**: point Caddy at the Syncthing host IP. Restrict TCP 8384 to the Caddy host IP on the host firewall.

```
########## SYNCTHING (host mode)
syncthing.domain.tld {
    import use_tls
    import errorHandling

    reverse_proxy <syncthing-host-ip>:8384 {
        header_up Host {upstream_hostport}
    }
}
```

## Host Mode Firewall

In host mode Syncthing listens on the host ports directly, so host firewall rules are the access control layer.

- TCP 8384 (GUI): allow only from the reverse-proxy host.
- TCP 22000, UDP 22000, UDP 21027: scope per the reachability mode below.
- Deny or drop all other sources for these ports.

### Reachability Modes

**1. LAN-only sync** (most restrictive)

- Allow sync ports from your LAN/admin subnet only, for example `192.168.x.0/24`.
- No router port forwarding needed. Devices off the physical network cannot sync until back on LAN or on a VPN.

**2. Open sync across the internet**

- Allow sync ports from `0.0.0.0/0`. Keep TCP 8384 restricted to the proxy host.
- Router: forward external TCP 22000, UDP 22000, and UDP 21027 to the host's LAN IP.
- Risk: anyone can reach and fingerprint the port as Syncthing. They cannot pair or pull data without your device ID (TLS plus device-ID pinning; unknown devices are rejected by default). This makes Syncthing the internet-facing service on the box, so keep the image updated.

**3. VPN-based sync** (recommended follow-up)

- Install a VPN mesh such as Tailscale on the host and remote devices.
- Scope sync ports to LAN plus the VPN subnet, for example `100.64.0.0/10`, or specific VPN device IPs.
- Remove the router port forward. Keep TCP 8384 restricted to the proxy host.

## Mounting Host Folders

Sync folders are added as bind mounts in `docker-compose.override.yml` and then registered as folders inside the Syncthing UI. The container path (right side of the `:`) is what you enter in the Syncthing UI when adding a folder. Mounts in the override file are appended to the base `./conf:/config` mount; an override line targeting `/config` replaces it.

### Generic Host Directory

In `docker-compose.override.yml`:

```yaml
services:
  syncthing:
    volumes:
      - /path/on/host:/data/foldername
```

Then in the Syncthing UI, add the folder path `/data/foldername`.

`PUID`/`PGID` should match the owner of the host directory so Syncthing can read and write files.

---

### Nextcloud AIO Data Directory

Nextcloud AIO runs its containers with UID/GID `33` (`www-data`). To allow Syncthing to write into the Nextcloud data directory, **Syncthing must also run as UID/GID 33**.

In `docker-compose.override.yml`, using the `NEXTCLOUD_DATADIR` value from the Nextcloud service's `.env`:

```yaml
services:
  syncthing:
    environment:
      - PUID=33
      - PGID=33
    volumes:
      - /path/to/nextcloud/data/ncdata:/data/nextcloud
```

> The full path to a given user's files inside the container is:
> `/data/nextcloud/<username>/files/`

In the Syncthing UI, add the folder at `/data/nextcloud/<username>/files/` (or a subdirectory within it).

#### Mixing Nextcloud and Other Sync Folders (UID Conflict)

Running Syncthing at `PUID=33` means it runs as `www-data` inside the container. If you also want to sync host directories owned by a different user (e.g. UID 1000), Syncthing will not have write access to those directories.

**Option A - Two Syncthing instances (recommended for mixed workloads)**

Add a second service in `docker-compose.override.yml` with a separate config path, `PUID`/`PGID` matching the other directories' owner, and different host port mappings. Proxy each instance to its own subdomain.

**Option B - POSIX ACLs on the non-Nextcloud directories**

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

If the host has an external volume mounted at a path like `/mnt/mynas`, bind-mount it in `docker-compose.override.yml`:

```yaml
services:
  syncthing:
    volumes:
      - /mnt/mynas:/data/mynas
```

Then in the Syncthing UI, add the folder path `/data/mynas` (or a subdirectory).

> The host mount must be active before the Syncthing container starts. If the mount is absent at startup, Docker will create an empty directory at that path instead of using the NAS volume.

---

## Backup and Restore

### Backup

- Include this entire directory in backups, including the untracked `docker-compose.override.yml`.
- The config directory (`./conf` unless overridden) contains all Syncthing configuration, device certificates, and folder metadata.

### Restore

- Replace this entire directory and the config directory from backup.
- Launch container.

## Resources

- <https://syncthing.net/>
- <https://docs.syncthing.net/>
- <https://hub.docker.com/r/linuxserver/syncthing>
- <https://docs.linuxserver.io/images/docker-syncthing/>
