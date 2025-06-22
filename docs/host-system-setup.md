# Host System Setup

Linux is preferred for a server. I tend to run Debian-based distros, but any Linux distro should work fine. Since stuff is mostly Docker-based, Outpost can also be run on a local workstation as `localhost`, including MacOS (partially tested) and theoretically Windows (if you *must*, not tested, some mods probably necessary). All setup and commands in this repo assume a Linux (Debian) host, so YMMV.

**Outline**
- [Filesystem Setup Notes](#filesystem-setup-notes)
   - [Optional NFS Considerations](#optional-nfs-considerations)
- [Install Docker](#install-docker)

## Filesystem Setup Notes

It's general best practice to run any apps / functions on a separate partition than the root OS.
- *Option 1:* Partition the hard drive to separate `/` (root) and everything else. At minimum, if you blow through the available storage at least you haven't also crippled the operating system.
- *Option 2:* Mount a separate drive for data.
- *Option 3:* Mount a shared drive for data, e.g. using NFS. This has the added benefit of separating the data storage function onto a separate server from the apps / services function. But introduces extra complications. It's best suited for user files that need to be shared across systems, whereas databases are better saved on the local file system (e.g., `/srv`), then properly backed up

I've configured this project to default to *Option 2* above. The `/srv` directory is assumed to be on a separate drive from the OS. 
- Docker is configured (see *Docker Daemon Settings* below) to use `/srv/docker` as the default location for docker-related files (containers, volumes, logs, etc.) instead of the standard `/var/lib/docker`.
- Containers and services will by default save persistent data to various folders in `/srv`, as indicated in the `template-env` files.

### Optional NFS Considerations

For using NFS to work:
1. The NFS server must enable the `all_squash` setting on the export.
2. The NFS client config must include the configuration options `user` (allow non-root user to mount) and `rw` (read-write).
3. Any user account that needs read-write access to the share, including system users leveraged by containers, must be added to the `nogroup` group
   ```
   sudo usermod -a -G nogroup <username>
   ```
4. Environment variables for data storage will need to be updated based on the relevant NFS share location on the **Outpost** host file system.

Individual services may have additional considerations when relying on NFS storage mounted to the host. These are documented in service readme files.

## Install Docker

Install [Docker](https://docs.docker.com/get-docker/) & [Docker Compose](https://docs.docker.com/compose/install/) according to the latest Docker instructions.

Consider then changing the default Docker storage location and adding automatic log rotation. See:
- [Change Docker Storage Location](./change-docker-storage-location.md)
- [daemon.json](./daemon.json)
