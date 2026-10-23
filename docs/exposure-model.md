# Exposure Model

This document records the agreed exposure model for the services in this repository: which tier
each service is reachable from, what gates access in that tier, and the rules that keep the model
consistent as services are added.

It describes decisions, not an implementation. Where an item is not built yet, that is stated.

## Tiers

There are three tiers. A service belongs to exactly one tier for each surface it exposes, so a
service with a public share surface in addition to a private application surface appears in two
rows of the per-service table below.

| Tier          | Reachable from       | Services                                                                 |
| ------------- | -------------------- | ------------------------------------------------------------------------ |
| Public        | Internet             | Immich share hostname only                                               |
| VPN (tailnet) | Tailnet members only | Immich app, Nextcloud, Wallabag, Syncthing, Dashy, Authentik, Proxmox UI |
| LAN           | User LAN, via Caddy  | CyberChef, Speedtest                                                     |

The Public tier carries one hostname. It is the Immich share surface, and it is gated by a
Cloudflare Access one-time PIN before any request reaches the origin. Nothing else is published to
the internet: not the Immich application, not the identity provider, not the dashboards.

The VPN tier is reachable over the tailnet only. Tailscale device membership is the transport-level
control; per-service authentication sits on top of it and is listed in the next section.

The LAN tier is reachable from the user LAN through Caddy. These services are unauthenticated by
design; the network position is the entire control.

## Per-service gate

| Service         | Repo path              | Tier          | Gate                                         |
| --------------- | ---------------------- | ------------- | -------------------------------------------- |
| Authentik       | `./01_authentik/`      | VPN (tailnet) | Its own login plus MFA                       |
| Caddy           | `./00_proxy/`          | Edge          | None; terminates TLS and routes              |
| CyberChef       | `./cyberchef/`         | LAN           | None; unauthenticated                        |
| Dashy           | `./dashy/`             | VPN (tailnet) | Native login; tailnet is the primary control |
| Immich (app)    | `./immich/`            | VPN (tailnet) | Authentik OIDC                               |
| Immich (shares) | `./immich/`            | Public        | Cloudflare Access one-time PIN               |
| Nextcloud       | `./nextcloud/`         | VPN (tailnet) | Authentik OIDC                               |
| Proxmox UI      | not in this repo       | VPN (tailnet) | Host login; tailnet is the primary control   |
| Speedtest       | `./speedtest-tracker/` | LAN           | None; unauthenticated                        |
| Syncthing       | `./syncthing/`         | VPN (tailnet) | Native auth; sync ports on the tailnet only  |
| Wallabag        | `./wallabag/`          | VPN (tailnet) | Native login plus TOTP                       |

Caddy is listed as an edge component rather than a tier member: it is the ingress for the LAN tier
and, behind the tunnel, for the Public tier.

## The invariant

> User LAN has exactly one ingress, and Caddy can reach everything that must be reachable from the
> user LAN.

Every LAN-reachable service is reached through Caddy on port 443. No service publishes on
`0.0.0.0`, and no second ingress from the internet exists. Caddy must be able to reach every service
the user LAN is expected to reach, so a service that is bound to the host network or published on a
loopback address needs an explicit route from Caddy. If a new service cannot satisfy both halves of
the invariant, the model changes before it ships.

## Port publication

Where each surface listens, and what the address alone does and does not prove:

| Surface              | Binding                                                   |
| -------------------- | --------------------------------------------------------- |
| Authentik            | `127.0.0.1:9000` and `127.0.0.1:9443` (loopback only)     |
| Caddy                | `${BIND_ADDR}:443`                                        |
| App ports on server2 | `${BIND_ADDR}:${PORT}` per service                        |
| Syncthing sync       | `${TAILSCALE_ADDR}:22000/tcp`, `:22000/udp`, `:21027/udp` |
| Syncthing web UI     | `${BIND_ADDR}:8384`, proxied by Caddy like every other UI |

`BIND_ADDR` is the host LAN address and `0.0.0.0` is never used. The LAN-facing bind is not
optional: Caddy runs on server1 and the applications run on server2, so the proxy reaches them over
the user LAN. That means the bind address does not by itself make a port Caddy-only. What makes it
Caddy-only is the `prerouting` chain in `docs/nftables-server2.nft`, which runs before Docker's DNAT
and accepts those ports from server1 and from nowhere else. Without that chain a `BIND_ADDR` port is
reachable from the whole user LAN.

Syncthing splits into two surfaces and shows the rule: the sync ports bind to `${TAILSCALE_ADDR}`
because that traffic is tailnet-only, while the web UI is a browser surface and therefore goes
through Caddy on `BIND_ADDR`.

## Authentication policy

The rule that decides between a proxy-side gate and application-native authentication:

> `forward_auth` is only correct for browser-only surfaces that have no native clients and no API
> consumers. Everything else uses OIDC.

A cookie-based gate is a browser construct. Applying it to a service with non-browser clients breaks
those clients, because they cannot complete an interactive login redirect. In practice a
`forward_auth` gate breaks:

- Nextcloud DAV sync, including desktop and mobile clients,
- the Immich mobile app and its background upload,
- the Wallabag mobile app and its share extension,
- API keys and long-lived tokens, which have no browser session to reuse,
- public share links, opened by people who have no account and no cookie.

OIDC keeps authentication inside the application, where the client can use its own token or app
password while the browser still gets a single-sign-on redirect. Wallabag, Dashy, Syncthing and the
Proxmox UI keep their native authentication, with the tailnet as the transport-level control.
Nextcloud and Immich use Authentik OIDC because their client ecosystems need real application
tokens rather than a proxy cookie.

## Operational consequence

Authentik is on the login path for Nextcloud and Immich. If Authentik is down, no Nextcloud or
Immich login is possible, including for administrators. This is a deliberate trade, accepted in
exchange for centralised identity and MFA.

Mitigation: keep a local break-glass administrator account in each application, with credentials
stored outside the identity provider, and confirm it still works after any Authentik change. The
break-glass accounts are the recovery path, so they are not used for routine administration.

## Cloudflare exit procedure

Not built. Documented so the swap is a bounded operation rather than a migration project.

The exit replaces cloudflared with a small VPS running Caddy and CrowdSec, connected to server1 by a
WireGuard link:

1. Provision the VPS and install Caddy and CrowdSec.
2. Establish the WireGuard link from the VPS to server1.
3. Move DNS for the public hostname to the VPS.
4. On the VPS, terminate TLS and reverse proxy the public hostname across WireGuard to the Caddy
   instance on server1.
5. Remove the cloudflared container from `./00_proxy/`.

Caddy keeps owning TLS and routing for the internal tiers, so the swap touches one container and
one DNS record. The Cloudflare Access one-time PIN on the public share hostname is replaced by an
access control decision at the VPS edge; that decision has to be defined before the cutover, not
during it.

Trigger conditions for doing it:

- routing large volumes of media through the tunnel, or
- a second and third public service appearing.

Absent either condition, the tunnel is the cheaper and smaller-surface option.

## Deferred decisions

Considered and deliberately not adopted in this phase. Each is a candidate for a later phase.

| Item                          | Reason                                                                        |
| ----------------------------- | ----------------------------------------------------------------------------- |
| Portainer                     | Removed: needs a writable Docker socket; status via `docker context` over SSH |
| Headscale                     | Hosted control plane works; self-hosting it adds a critical service.          |
| Wazuh                         | Drop-logging digest covers host telemetry; Wazuh is large for two hosts.      |
| Prometheus and Grafana        | No metrics consumer yet; collection without alert rules is not a decision.    |
| Authelia instead of Authentik | Authentik is deployed and integrated; swapping IdPs is a migration.           |
| pfSense re-segmentation       | pfSense is physical, so segmented inter-VM traffic would go on the wire.      |

Re-segmentation and the east-west position are set out in more detail in `docs/east-west.md`.
