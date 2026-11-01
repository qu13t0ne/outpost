# Exposure Model

This document records the agreed exposure model for the services in this repository: which lane
each service is reachable from, what gates access in that lane, and the rules that keep the model
consistent as services are added.

It describes decisions, not an implementation. Where an item is not built yet, it is stated.

> **Status: model.** This document describes the target and marks each row with what is
> actually enforced. Read the status column before relying on a gate. The model is the part
> worth copying into another estate; the status columns describe one deployment of it and will
> not match yours.

`server1` and `server2` below are the **two-host example names** for the option-2 layout in the
README -- the proxy host and the application host. On a single host (option 1) they collapse to one
machine and the application ports are not published at all.

## The lanes and controls

A _lane_ answers "from which network can a request arrive"; a _control_ is "what stops the request."
Two lanes carry a control that is not the mere fact of being on a network.

- The **user LAN** is a physical segment and is not flat. It splits into a **user segment** and a
  **server segment**, and the perimeter firewall (pfSense) sits between them: a user-segment host
  may reach the _exposed surface_ (Caddy) on the server segment, and nothing else.
- The **tailnet** is split by **device class**. An **admin device** (used only by the operator)
  reaches the services and the **admin surface**; a **user device** (family, shared, or roaming)
  reaches the services but **not the admin surface**.

| Lane or surface    | Reachable from           | Gate                                    |
| ------------------ | ------------------------ | --------------------------------------- |
| Public             | The internet             | A Cloudflare Access one-time PIN        |
| Exposed surface    | User segment and tailnet | Per service; one Caddy route on 443     |
| Admin surface      | Tailnet, admin device    | Tailscale device class, plus host login |
| Consumer (TV, IoT) | User segment only        | None: it reaches an exposed surface     |

A service is placed by the lanes it exposes, and it may expose more than one. The **exposed
surface** reaches from the user segment and the tailnet alike; the **admin surface** reaches from the
tailnet on an admin device only, never from the user segment or the internet. Each is described
below, along with the device that has no lane at all.

### The Public lane

The Public lane carries one hostname. It is the Immich share surface, and it is meant to be gated
by a Cloudflare Access one-time PIN before any request reaches the origin.

> **Status: not built in this deployment.** Eight hostnames are published on the tunnel and no
> access application exists on any of them, so the tunnel currently carries no authentication
> gate at all and one site block is genuinely reachable from the internet without one. The model
> above is the target; the gate is a deployment step.

Nothing else is published to the internet: not the Immich application, not the identity provider,
not the dashboards.

### The tailnet, split by device class

The tailnet is reachable by any Tailscale member, from anywhere. Device membership is the
transport-level control and per-service authentication sits on top of it. **Device class** is a
second, independent control _inside_ the tailnet: an admin device reaches the admin surface, a user
device does not. Tailscale device tags are the mechanism; the policy shape is the template in
[`../net/tailscale-policy.hujson`](../net/tailscale-policy.hujson), and the devices that occupy its
classes are the operator's own information, not this repository's.

> **Status: modelled, not applied.** In this deployment the policy is the allow-all default, so a
> tag constrains nothing yet. An allow-all default is the shape a migration starts from; it is
> never the shape it ends in.

### The exposed surface, and the user segment

Every data service and every Caddy-routed tool -- Immich, Nextcloud, Wallabag, Dashy, Syncthing,
CyberChef, and Speedtest -- is an **exposed surface**: one Caddy route on 443, reachable from the
user segment and from the tailnet. Reachability decides the lane, not a per-request test. CyberChef
and Speedtest are deliberately **unauthenticated**; on that surface a request from either lane gets
the same service, which is why they are now on both the user segment and the tailnet. The only
surface that stays off one of those lanes is the admin surface, below.

### The admin surface -- two parallel controls

The **admin surface** (the jumpbox, the hypervisor console, and the administrative reach of the
identity provider) is reachable from the tailnet on an **admin device** only. It is not reachable
from the user segment and not reachable from the internet, by design. Its security rests on two
parallel controls that **must both hold**:

- the perimeter firewall keeps it **off the user segment**: a user-segment host, no matter how
  compromised, cannot reach it, because the firewall admits the user segment only to the exposed
  surface;
- the device-class split keeps it **off every non-admin device**: a user or family device, no matter
  where it sits, cannot reach it, because Tailscale routes it to the services and not to the admin
  surface.

Each guards a different vector. The firewall guards a compromised _physical_ host on the user
segment; the device-class split guards a compromised _roaming_ device. Drop one and the other vector
leaks, so both must hold. That is the whole reason the user/server re-segmentation is now adopted.

> **Status: neither control is enforced yet in this deployment.** The overlay policy accepts every
> member, and the perimeter admits the user segment to the whole server segment, so the admin surface
> is reachable from both vectors today. The two controls are deployment steps, not existing facts.

### The consumer

A device that exposes nothing -- a Roku, a smart TV, an IoT node, or a phone that is on the user
segment only -- has no lane. It is a **consumer**: it reaches a service's exposed surface (for
example a future Jellyfin instance) from the user segment. It has no lane of its own, because it
exposes nothing: the question "where does this device go" is answered by the _service_ it needs, not
by the device.

## Per-service gate

| Service         | Reachable from      | Gate                                         | Enforced today |
| --------------- | ------------------- | -------------------------------------------- | -------------- |
| Immich (app)    | tailnet + user LAN  | Authentik OIDC                               | No; native accounts. Identity provider not deployed |
| Nextcloud       | tailnet + user LAN  | Authentik OIDC                               | No; native accounts. Identity provider not deployed |
| Wallabag        | tailnet + user LAN  | Native login plus TOTP                       | Login yes. Also reachable from the internet with no gate, which is a defect against this model |
| Dashy           | tailnet + user LAN  | Native login; tailnet is the primary control | Login yes; the tailnet half is not enforced, because the policy accepts everybody |
| CyberChef       | tailnet + user LAN  | None; unauthenticated                        | Yes; unauthenticated is the design |
| Speedtest       | tailnet + user LAN  | None; unauthenticated                        | Yes; unauthenticated is the design |
| Syncthing (UI)  | tailnet + user LAN  | Native; sync ports on the tailnet only       | No; sync ports still bind widely and are reachable on the local segment |
| Immich (shares) | internet            | Cloudflare Access one-time PIN               | No; no access application exists on any tunnelled hostname |
| Authentik       | tailnet + user LAN  | Own login plus MFA; container loopback-bound | Not deployed |
| Hypervisor UI   | tailnet, admin only | Host login; not reachable from the user LAN  | Not yet; the perimeter admits the user segment to it |

The right-hand column is the honest one. A model that reads as description is how an estate ends
up believing it has gates it never built, which is exactly what happened here: this table was
written as present tense while half of it was intent.

Caddy is an edge component rather than a lane: it is the single ingress for the exposed surface
(reachable from the user segment and the tailnet) and, behind the tunnel, for the Public lane.
The `jumpbox` is the operator's SSH entry to the server segment; it is on the admin surface.

## The invariant

> The user segment has exactly one ingress, and Caddy can reach everything that must be reachable
> from the user segment.

Every user-segment-reachable service is reached through Caddy on port 443. No service publishes on
`0.0.0.0`, and no second ingress from the internet exists. Caddy must be able to reach every service
the user segment is expected to reach, so a service that is bound to the host network or published on a
loopback address needs an explicit route from Caddy. If a new service cannot satisfy both halves of
the invariant, the model changes before it ships.

The perimeter firewall enforces the first half: the user segment reaches only the exposed surface,
and the admin surface is not reachable from it at all. The bind address does not enforce anything by
itself -- *Port publication* shows why -- so the two controls are the firewall between segments and
the host ruleset within the segment.

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
optional: Caddy runs on server1 and the applications run on server2, so the proxy reaches them across
the server segment. That means the bind address does not by itself make a port Caddy-only. What makes
it Caddy-only is the `prerouting` chain in `docs/nftables-server2.nft`, which runs before Docker's
DNAT and accepts those ports from server1 and from nowhere else. Without that chain a `BIND_ADDR`
port is reachable from every host on that LAN.

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
password while the browser still gets a single-sign-on redirect. Wallabag, Dashy, Syncthing and a
hypervisor console keep their native authentication, with the tailnet as the transport-level control.
Nextcloud and Immich use Authentik OIDC because their client ecosystems need real application
tokens rather than a proxy cookie.

## Operational consequence

Authentik is on the login path for Nextcloud and Immich. If Authentik is down, no Nextcloud or
Immich login is possible, including for administrators. This is a deliberate trade, accepted in
exchange for centralised identity and MFA.

> **Status: not yet true.** Neither application is behind the identity provider in this
> deployment; both still authenticate against local accounts. The trade stated above is being
> accepted in advance, which is the point of writing it down before a cutover rather than
> discovering it during one.

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

Caddy keeps owning TLS and routing for the internal lanes, so the swap touches one container and
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
| Authelia instead of Authentik | The modelled identity provider is not deployed yet, so this is still an open choice rather than a migration |

The **perimeter user/server re-segmentation** has left this list: it is adopted, and it is the
boundary that admits only the exposed surface to the user segment. The remaining items stay
deferred. The re-segmentation and the east-west position are set out in `docs/east-west.md`; the
order of operations is in the operator's private lab notes.
