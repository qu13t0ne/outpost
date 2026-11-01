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

## Design Assumptions

Two assumptions sit under everything else here. Both show up in the configuration rather than in
one place, so neither can be described as a single setting. If an assumption does not hold for your
estate, the change is in the files named beside it.

**There is an overlay network.** Each host carries a second, stable address on a WireGuard-class
overlay, and each device that needs in-home access has an identity on it. The reference deployment
uses Tailscale, so the placeholder address in these files is `100.64.0.0/10`; the requirement is
the capability, not the vendor.

This is not decorative. `syncthing` binds its sync ports to `${TAILSCALE_ADDR}` and
`config.example/outpost.env` carries that address; the proxy publishes a second listener on its overlay
address, because a
device that is on the overlay only cannot route to the host's LAN address; both guest nftables
templates define `TAILNET` and key rules off it; and every "reachable on the tailnet and the user
LAN" line in the component list below depends on it. The device-class policy that separates an
admin device from a family device is authored in [`net/`](./net/) as a template, since the classes
are generic and the devices that occupy them are not.

Without an overlay the composition still serves over the user LAN and the tunnel, but four things
go away: the proxy's second listener, tailnet-only sync ports, device-class separation, and remote
access that does not open the firewall. If your estate has no overlay, delete the `TAILSCALE_ADDR`
mappings and the `TAILNET` defines. Do not leave them in place pointing at an address that does not
exist: `docker compose` resolves a missing variable to an empty string, so the mapping becomes
`:22000:22000` and the container fails at start rather than falling back.

**One ingress, and every published port names an address.** Caddy on 443 is the only thing that
serves a request from any lane, whether that request arrived over the LAN, the tunnel or the
overlay. No service publishes on `0.0.0.0`; each port is bound to `BIND_ADDR`, the host's LAN
address. A wildcard listener silently becomes a second ingress on every interface the host has,
which is what the nftables templates exist to catch. The lanes and the controls are in the
[exposure model](./docs/exposure-model.md).

## Components Overview

- **Reverse Proxy, Internet Access, and IAM**
  - [Caddy Reverse Proxy](./00_proxy/) - Provides reverse proxy to all hosted services
  - [Cloudflared](./00_proxy/) - Provides reverse proxy from Internet to Caddy without opening the firewall or messing with dynamic DNS on the host machine
  - [Authentik](./01_authentik/) - Identity provider for OIDC single sign-on; an exposed surface on
    the tailnet and user LAN with its own login and MFA, never on the internet. Wiring:
    [Authentik OIDC runbook](./docs/authentik-oidc.md)
- **Monitoring:**
  - Portainer was removed from this repo. Container status and logs come from `docker context` over
    SSH, plus Dozzle if a web view is wanted, so no service holds a writable Docker socket. Portainer
    needed one, and a writable socket is a host root path for anything that can reach the UI.
- **Apps and Services**
  - [CyberChef](./cyberchef/) - Cyber Swiss Army Knife web app; exposed, reachable on the tailnet
    and the user LAN, no gate because it is client-side only
  - [Dashy](./dashy/) - Dashboard and start page, reachable on the tailnet and the user LAN
  - [Immich](./immich/) - Self-hosted photo and video management solution, reachable on the tailnet
    and the user LAN, plus a public share surface
  - [Nextcloud](./nextcloud) - Flexible open source file synchronization and sharing solution,
    reachable on the tailnet and the user LAN
  - [Syncthing](./syncthing/) - File synchronization service, reachable on the tailnet and the user
    LAN, with sync ports on the tailnet only
  - [Speedtest Tracker](./speedtest-tracker/) - Network speed monitoring app; exposed, reachable on
    the tailnet and the user LAN
  - [Wallabag](./wallabag/) - Read-it-later solution, reachable on the tailnet and the user LAN

The lanes and controls are defined in [the exposure model](./docs/exposure-model.md). Each service
directory publishes its port on the host LAN address from `BIND_ADDR`, never on `0.0.0.0`, and the
app host's nftables ruleset accepts those ports from the proxy host only.

<!-- Archived; these now live under x_archive/. -->
<!-- - **[Adminer](./x_archive/x_adminer/)** - Database management web UI -->
<!-- - **[MongoDB](./x_archive/x_mongodb/)** - MongoDB non-relational database -->
<!-- - **[PostgreSQL and pgAdmin](./x_archive/x_postgres/)** -->
<!-- - **[Budibase](./x_archive/x_budibase/)** - Low-code platform  -->
<!-- - **[PhotoPrism](./x_archive/x_photoprism/)** - Photos management app -->

## Documentation

- [Exposure model](./docs/exposure-model.md) - the lanes and controls, which service sits in which,
  the user/server re-segmentation, the single-ingress invariant, the authentication policy, and the
  Cloudflare exit plan
- [Overlay policy](./net/) - the device-class access policy as a template, the substitution rules,
  and the rule that denial is the absence of a line
- [East-west security](./docs/east-west.md) - why pfSense cannot filter traffic between the two
  servers, the layers that do, and the accepted residual risks
- [Authentik OIDC runbook](./docs/authentik-oidc.md) - wiring single sign-on into Nextcloud and
  Immich, including break-glass and the usual failure modes
- [Host System Setup](./docs/host-system-setup.md) - filesystem layout and Docker install
- [Configuration model](./docs/config-model.md) - where personal configuration lives, how it is
  resolved, why two env files per service, and how to migrate an existing `.env`

## Admin And Dev Machine Prerequisites

These are the tools used to author, lint and validate this repository from a workstation or build box
that is **not** a deployment host. None of them turns the machine into a server, and none is required
on the deploy host beyond Docker itself. `just check` prints `SKIP` for each tool it cannot find, so a
missing one costs verification, not correctness.

| Tool             | Used by                     | What it does                                                  |
| ---------------- | --------------------------- | ------------------------------------------------------------- |
| `just`           | every recipe                | runs the task definitions in the `justfile`                   |
| `docker compose` | `just check`, run recipes   | validates and runs compose files; `config` needs no daemon    |
| `gitleaks`       | `just check`, pre-commit    | scans for secrets before commit and push                      |
| `trufflehog`     | history scan                | second secret engine; verifies whether a credential is live   |
| `hadolint`       | `just check`                | lints `00_proxy/Dockerfile`                                    |

`docker compose` is needed only for the `config` subcommand and `just check`. That subcommand parses
and interpolates YAML without contacting the Docker daemon, so Docker Desktop is not required for
validation. The `justfile` uses the spaced form `docker compose`, which is the v2 CLI plugin, not the
old standalone `docker-compose`.

### macOS

```sh
brew install just docker-compose gitleaks trufflehog hadolint
```

`docker-compose` installs the v2 plugin so the spaced form works. The other four are single binaries
from their formulae.

### Debian / Ubuntu

```sh
# just: packaged on Debian 13+ and Ubuntu 23.10+. Where apt has no package, use the official
# installer instead.
sudo apt install just
#   curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin

# docker compose v2 plugin (provides `docker compose`; no daemon needed for `config`).
# On older releases add Docker's apt repo and install docker-compose-plugin.
sudo apt install docker-compose-v2

# trufflehog: official installer
curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh \
  | sh -s -- -b /usr/local/bin

# gitleaks: release binary (see https://github.com/gitleaks/gitleaks/releases), or via Go below
sudo wget -O /tmp/gitleaks.tar.gz \
  https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_x64.tar.gz
sudo tar -xzf /tmp/gitleaks.tar.gz -C /usr/local/bin gitleaks

# hadolint: static binary (arm64: hadolint-Linux-arm64)
sudo wget -O /usr/local/bin/hadolint \
  https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64
sudo chmod +x /usr/local/bin/hadolint
```

`gitleaks` and `trufflehog` are Go programs; `go install github.com/gitleaks/gitleaks/v8@latest` and
`go install github.com/trufflesecurity/trufflehog/v3@latest` both work where a Go toolchain is present,
writing to `$(go env GOPATH)/bin` (add that to `PATH`). Release pages are the source of truth for the
current version; the version in the `gitleaks` URL above tracks `.pre-commit-config.yaml`.

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

The documentation under `docs/`, including the per-service `${BIND_ADDR}` port patterns in the
service readmes and the `docs/nftables-*.nft` guest rulesets, describes that option-2 layout. On
option 1 (single host) the proxy and the applications share one Docker network, so an application
port is not published at all: Caddy reaches the app by container name over the `outpost` network,
and the guest nftables ruleset does not apply.

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

### Where Configuration Lives

Personal configuration is not held in this repository. It is read from a directory that resolves in one
place (the `justfile`), and `config.example/` is the only config-shaped thing the tree commits. The
model, the two-env-file split, and the migration path are in [docs/config-model.md](./docs/config-model.md).

Quickstart:

```
just init            # create $OUTPOST_CONFIG_DIR/ from config.example/ (default: $HOME/.config/outpost)
# edit the real values in the files just init reported, per service
just up 00_proxy     # start a service; reads $OUTPOST_CONFIG_DIR/00_proxy/compose.env and app.env
```

Every service recipe (`up`, `down`, `pull`, `logs`, `ps`) reads its configuration from the resolved
directory, never from inside the tree. A directory that does not resolve is a failure that prints the
fix, not a default that puts personal state back where it can be published.

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
