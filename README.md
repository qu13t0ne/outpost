# OUTPOST - A Self-Sufficient, Self-Hosted Cloud Setup
```
 ▄▄▄▄▄▄▄▄▄▄▄  ▄         ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
▐░█▀▀▀▀▀▀▀█░▌▐░▌       ▐░▌ ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀  ▀▀▀▀█░█▀▀▀▀ 
▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌     ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌               ▐░▌     
▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌     ▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄▄▄      ▐░▌     
▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌     ▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌     ▐░▌     
▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌     ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌       ▐░▌ ▀▀▀▀▀▀▀▀▀█░▌     ▐░▌     
▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌     ▐░▌          ▐░▌       ▐░▌          ▐░▌     ▐░▌     
▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌     ▐░▌     ▐░▌          ▐░█▄▄▄▄▄▄▄█░▌ ▄▄▄▄▄▄▄▄▄█░▌     ▐░▌     
▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░▌     ▐░▌          ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░▌     
 ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀       ▀       ▀            ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀       ▀      
```
<!-- Ascii Text: Electronic font from https://www.coolgenerator.com/ascii-text-generator -->

## Description

Stand-alone self-hosting infrastructure with security and a range of apps. Caddy for reverse proxy plus generally heavy use of Docker. Easy and straightforward to add more services as need.

Build yourself an outpost.

*Repo URL: [https://github.com/mikeo85/outpost](https://github.com/mikeo85/outpost)*

* * * * *

## Components Overview

### Core Infrastructure & Security

- **[Caddy v2 Reverse Proxy](./caddy/)**
   - Including Caddy-Security for user authentication & MFA
   - *Note:* Be sure to read the [Important Reverse Proxy Setup Information](./caddy/readme.md#important-reverse-proxy-setup-information) in the [Caddy readme](./caddy/readme.md) file.

<!-- ### Databases -->

<!-- - **[PostgreSQL and pgAdmin](./postgres/)** -->

### Apps & Services

- **[Flame Startpage](./flame/)** - Easy startpage and bookmarks page
- **[CyberChef](./cyberchef/)** - Cyber Swiss Army Knife web app
- **[Nextcloud](./nextcloud)** - Flexible open source file synchronization and sharing solution
- **[Budibase](./budibase/)** - Low-code platform 
- **[PhotoPrism](./photoprism)** - Photos management app

## Installation and Setup

### Summary

1. Prep your host system.
2. Follow startup instructions on each of the component readme pages linked below.

### Prep Host System

Linux is preferred for a server. I tend to run Debian-based distros, but any Linux distro should work fine. Since stuff is mostly Docker-based, Outpost can also be run on a local workstation as `localhost`, including MacOS (partially tested) and theoretically Windows (if you *must*, not tested, some mods probably necessary). All setup and commands in this repo assume a Linux (Debian) host, so YMMV.

#### Filesystem Setup Notes

It's general best practice to run any apps / functions on a separate partition than the root OS.
- *Option 1:* Partition the hard drive to separate `/` (root) and everything else. At minimum, if you blow through the available storage at least you haven't also crippled the operating system.
- *Option 2:* Mount a separate drive for data.
- *Option 3:* Mount a shared drive for data, e.g. using NFS. This has the added benefit of separating the data storage function onto a separate server from the apps / services function. But introduces extra complications. It's best suited for user files that need to be shared across systems, whereas databases are better saved on the local file system (e.g., `/srv`), then properly backed up

I've configured this project to default to *Option 2* above. The `/srv` directory is assumed to be on a separate drive from the OS. 
- Docker is configured (see *Docker Daemon Settings* below) to use `/srv/docker` as the default location for docker-related files (containers, volumes, logs, etc.) instead of the standard `/var/lib/docker`.
- Containers and services will by default save persistent data to various folders in `/srv`, as indicated in the `template-env` files.

##### Optional NFS Considerations

For using NFS to work:
1. The NFS server must enable the `all_squash` setting on the export.
2. The NFS client config must include the configuration options `user` (allow non-root user to mount) and `rw` (read-write).
3. Any user account that needs read-write access to the share, including system users leveraged by containers, must be added to the `nogroup` group
   ```
   sudo usermod -a -G nogroup <username>
   ```
4. Environment variables for data storage will need to be updated based on the relevant NFS share location on the **Outpost** host file system.

Individual services may have additional considerations when relying on NFS storage mounted to the host. These are documented in service readme files.

#### Install Docker

Install [Docker](https://docs.docker.com/get-docker/) & [Docker Compose](https://docs.docker.com/compose/install/) according to the latest Docker instructions.

#### Add Docker Daemon Settings

Add some default settings to the Docker daemon for log rotation and container privilege restriction.

- Review contents of the [daemon.json](./daemon.json) file in this repo.
- Check if a default `daemon.json` file has already been created by Docker.
```shell
ls /etc/docker/daemon.json
```
- **IF** a default file does not exist (meaning the above command returns something like `ls: cannot access '/etc/docker/daemon.json': No such file or directory`), **THEN**:
	- Copy the `daemon.json` file from this repo to the default docker location
	```shell
	sudo cp ./daemon.json /etc/docker/daemon.json
	```
- **ELSE** (i.e., a file already exists at `/etc/docker/daemon.json`):
	- Modify the existing file to add the settings from this repo's version.

Finally, restart the Docker daemon.
```shell
sudo systemctl restart docker.service
```

## Metadata

**Created By Mike Owens** | [GitHub](https://github.com/mikeo85) ~ [GitLab](https://gitlab.com/mikeo85) ~ [Mastodon](https://infosec.exchange/@m0x4d) 

**License: [MIT](LICENSE)** *(Covers the config & setup. Apps & services have their own licenses. Hack responsibly.)*

<!-- **Version History:** See [commits](../../commits) or [release history](../../releases). -->

## Resources and Acknowledgments
This project is built on plenty of help from other online resources and repos. I try to acknowledge them wherever possible, but I'm human so I've probably forgotten some.

- About open source licenses: [ChooseALicense.com](https://choosealicense.com) / [Open Source Initiative](https://opensource.org/licenses) / [Developer's Guide](https://www.toptal.com/open-source/developers-guide-to-open-source-licenses)
- https://github.com/DoTheEvo/selfhosted-apps-docker
- Caddy Security plugin: https://authp.github.io/
- https://github.com/docker/awesome-compose
