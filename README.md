# OUTPOST - A Self-Hosted Personal Cloud Setup
```
████▄   ▄     ▄▄▄▄▀ █ ▄▄  ████▄    ▄▄▄▄▄      ▄▄▄▄▀ 
█   █    █ ▀▀▀ █    █   █ █   █   █     ▀▄ ▀▀▀ █    
█   █ █   █    █    █▀▀▀  █   █ ▄  ▀▀▀▀▄       █    
▀████ █   █   █     █     ▀████  ▀▄▄▄▄▀       █     
      █▄ ▄█  ▀       █                       ▀      
       ▀▀▀            ▀                             
```
<!-- Ascii Text: Electronic font from https://www.coolgenerator.com/ascii-text-generator -->

## Description

Stand-alone self-hosting infrastructure with security and a range of apps. Caddy for reverse proxy plus generally heavy use of Docker. Easy and straightforward to add more services as need.

Build yourself an outpost.

*Repo URL: [https://github.com/qu13t0ne/outpost](https://github.com/qu13t0ne/outpost)*

* * * * *

## Components Overview

- **Reverse Proxy, Internet Access, and IAM**
   - [Caddy Reverse Proxy](./00_proxy/) - Provides reverse proxy to all hosted services
   - [Cloudflared](./00_proxy/) - Provides reverse proxy from Internet to Caddy without opening the firewall or messing with dynamic DNS on the host machine
- **Monitoring:**
   - [Portainer](./portainer) - Lightweight Docker management web UI (mostly I just use for status monitoring)
      - Note, there's also a parallel [Portainer-remoteproxy](./portainer-remoteproxy/) for use when Caddy is running on a separate host from where you want to run Portainer.
- **Apps and Services**
   - [CyberChef](./cyberchef/) - Cyber Swiss Army Knife web app
   - [Dashy](./dashboard_dashy/) - Dashboard and start page
   - [Nextcloud](./nextcloud) - Flexible open source file synchronization and sharing solution
   - [Speedtest Tracker](./speedtest-tracker/) - Network speed monitoring app
   - [Wallabag](./wallabag/) - Read-it-later solution

<!-- - **[Adminer](./adminer/)** - Database management web UI -->
<!-- - **[MongoDB](./mongodb/)** - MongoDB non-relational database -->
<!-- - **[PostgreSQL and pgAdmin](./postgres/)** -->
<!-- - **[Budibase](./budibase/)** - Low-code platform  -->
<!-- - **[PhotoPrism](./photoprism)** - Photos management app -->

## Installation and Setup

### Decide Deployment Architecture

For deployment architecture, there are two basic approaches:

1. All services on a single host.
2. Proxy services on one host and other services on one or more separate hosts. This option provides some additional segregation between the proxy functions and the various services and allows proxying to continue uninterrupted even if you accidentally bork an app server.

The decision here will impact how container networking is configured, i.e., when an internal Docker network can be used between containers vs. when a container should publish a port to the localhost for access by the proxy.
Not a big deal either way, just something to be aware of & potentially modify in the container configs.
Details below in relevant sections.

FWIW, I'm using option 2, with a host for proxy and a host for running apps.
Default saved configurations in most `docker-compose.yml` files will reflect this.

### Prep Host System

See [Host System Setup](./docs/host-system-setup.md).

### Proxy-Only: Create Docker Network

**Only on the host running the Caddy proxy:**

Create a shared network for the Caddy container to reach and proxy other docker containers on the host.

```
docker network create outpost
```

This is not required for containers running on a different host, as published ports will be used instead.

### Launch Proxy

Start with the proxy containers.
Go to [00_proxy](./00_proxy/) and follow the readme instructions to launch the containers.

### Launch Portainer Monitoring

Suggested: Run a Portainer container on each host.

- For use on the same host as the proxy: [Portainer](./portainer/)
- For use on a different host than the proxy: [Portainer-remotehost](./portainer-remotehost)

### Configure and Launch Other Apps and Services

Follow startup instructions on each of the component readme pages linked in the [Components Overview above](#components-overview).

## Metadata

**Created By Mike Owens** | [GitHub](https://github.com/qu13t0ne) ~ [GitLab](https://gitlab.com/qu13t0ne) ~ [Bluesky](https://bsky.app/profile/qu13t0ne.bsky.social)~ [Mastodon](https://infosec.exchange/@qu13t0ne) 

**License: [MIT](LICENSE)** *(Covers the config & setup. Apps & services have their own licenses. Hack responsibly.)*

## Resources and Acknowledgments
This project is built on plenty of help from other online resources and repos. I try to acknowledge them wherever possible, but I'm human so I've probably forgotten some.

- https://github.com/DoTheEvo/selfhosted-apps-docker
- https://github.com/docker/awesome-compose
