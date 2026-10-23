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
  - [Authentik](./01_authentik/) - Identity provider for OIDC single sign-on. VPN tier only, never
    internet-reachable. Wiring: [Authentik OIDC runbook](./docs/authentik-oidc.md)
- **Monitoring:**
  - Portainer was removed from this repo. Container status and logs come from `docker context` over
    SSH, plus Dozzle if a web view is wanted, so no service holds a writable Docker socket. Portainer
    needed one, and a writable socket is a host root path for anything that can reach the UI.
- **Apps and Services**
  - [CyberChef](./cyberchef/) - Cyber Swiss Army Knife web app (LAN tier)
  - [Dashy](./dashy/) - Dashboard and start page (VPN tier)
  - [Immich](./immich/) - Self-hosted photo and video management solution (VPN tier, plus a public
    share surface)
  - [Nextcloud](./nextcloud) - Flexible open source file synchronization and sharing solution (VPN tier)
  - [Syncthing](./syncthing/) - File synchronization service (VPN tier; sync ports on the tailnet)
  - [Speedtest Tracker](./speedtest-tracker/) - Network speed monitoring app (LAN tier)
  - [Wallabag](./wallabag/) - Read-it-later solution (VPN tier)

Tiers are defined in [the exposure model](./docs/exposure-model.md). Each service directory publishes
its port on the host LAN address from `BIND_ADDR`, never on `0.0.0.0`, and the app host's nftables
ruleset accepts those ports from the proxy host only.

<!-- Archived; these now live under x_archive/. -->
<!-- - **[Adminer](./x_archive/x_adminer/)** - Database management web UI -->
<!-- - **[MongoDB](./x_archive/x_mongodb/)** - MongoDB non-relational database -->
<!-- - **[PostgreSQL and pgAdmin](./x_archive/x_postgres/)** -->
<!-- - **[Budibase](./x_archive/x_budibase/)** - Low-code platform  -->
<!-- - **[PhotoPrism](./x_archive/x_photoprism/)** - Photos management app -->

## Documentation

- [Exposure model](./docs/exposure-model.md) - the three tiers, which service sits in which, the
  single-ingress invariant, the authentication policy, and the Cloudflare exit plan
- [East-west security](./docs/east-west.md) - why pfSense cannot filter traffic between the two
  servers, the layers that do, and the accepted residual risks
- [Authentik OIDC runbook](./docs/authentik-oidc.md) - wiring single sign-on into Nextcloud and
  Immich, including break-glass and the usual failure modes
- [Host System Setup](./docs/host-system-setup.md) - filesystem layout and Docker install

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
No container on the app host joins `outpost`: a Docker network cannot span hosts, so those services
publish a port on their LAN address and Caddy reaches them over the user LAN.

### Launch Proxy

Start with the proxy containers.
Go to [00_proxy](./00_proxy/) and follow the readme instructions to launch the containers.

### Configure and Launch Other Apps and Services

Follow startup instructions on each of the component readme pages linked in the [Components Overview above](#components-overview).

### Hardened Container Defaults

`compose.common.yml` at the repo root holds the defaults every service should run with:
`no-new-privileges`, `cap_drop: ALL`, a pids limit, a memory limit, and rotated logs. A read-only
root filesystem is documented there as a per-service opt-in, not a default, because most images write
somewhere at startup. The reasons for each are in the file.

Adoption is by `extends:`, which matches by reference rather than by name, so a service keeps its own
name:

```yaml
services:
  wallabag:
    extends:
      file: ../compose.common.yml
      service: _defaults
```

`include:` is deliberately not used: it merges by resource name, so the included service would have
to be called `_defaults` in the including file.

Phase 1 wired it into [template/docker-compose.yml](./template/docker-compose.yml) only, as the
reference implementation. Every other service keeps its current defaults and adopts this file in
Phase 3, one directory at a time, each verified with `docker compose config` before it is deployed.
Expect LinuxServer images to need a small, commented `cap_add` alongside `cap_drop: ALL`.

## Metadata

**Created By Mike Owens** | [GitHub](https://github.com/qu13t0ne) ~ [GitLab](https://gitlab.com/qu13t0ne) ~ [Bluesky](https://bsky.app/profile/qu13t0ne.bsky.social)~ [Mastodon](https://infosec.exchange/@qu13t0ne)

**License: [MIT](LICENSE)** *(Covers the config & setup. Apps & services have their own licenses. Hack responsibly.)*

## Resources and Acknowledgments

This project is built on plenty of help from other online resources and repos. I try to acknowledge them wherever possible, but I'm human so I've probably forgotten some.

- <https://github.com/DoTheEvo/selfhosted-apps-docker>
- <https://github.com/docker/awesome-compose>
