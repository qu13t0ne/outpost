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

## Installation and Setup

### Summary

1. Prep your host system.
2. Follow startup instructions on each of the component readme pages linked below.

### Prep Host System

Linux is preferred for a server. I tend to run Debian-based distros, but any Linux distro should work fine. Since stuff is mostly Docker-based, Outpost can also be run on a local workstation as `localhost`, including MacOS (partially tested) and theoretically Windows (if you *must*, not tested, some mods probably necessary). All setup and commands in this repo assume a Linux (Debian) host, so YMMV.

#### Specific Setup Notes

I like to run all Docker & services stuff out of a separate partition than root. If virtualized, I may even set this up as a separate virtual hard drive. Specifically, I'm using `/srv` for this. This has a few requirements/implications:
- Through partitioning and/or mounting a separate drive, separate `/srv` from `/` (root)
- Docker is configured (see *Docker Daemon Settings* below) to use `/srv/docker` as the default location for docker-related files (containers, volumes, logs, etc.) instead of the standard `/var/lib/docker`
- Containers and services will by default save persistent data to various folders in `/srv`, as indicated in the `template-env` files

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

## Components

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
- **[Budibase](./budibase/)** - low-code platform 

## Metadata

**Created By Mike Owens** | [GitHub](https://github.com/mikeo85) ~ [GitLab](https://gitlab.com/mikeo85) ~ [Twitter](https://twitter.com/quietmike8192)  
(With plenty of help from other online resources and repos that I try to acknowledge wherever possible.)

**License: [MIT](LICENSE)**

<!-- **Version History:** See [commits](../../commits) or [release history](../../releases). -->

## Resources and Acknowledgments

- About open source licenses: [ChooseALicense.com](https://choosealicense.com) / [Open Source Initiative](https://opensource.org/licenses) / [Developer's Guide](https://www.toptal.com/open-source/developers-guide-to-open-source-licenses)
- https://github.com/DoTheEvo/selfhosted-apps-docker
- Caddy Security plugin: https://authp.github.io/
- https://github.com/docker/awesome-compose
