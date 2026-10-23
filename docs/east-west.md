# East-West Traffic

This document records the server-LAN position: what filters traffic between server1 and server2,
what does not, and which risks are accepted as a result.

## The technical fact

pfSense is a physical appliance. When server1 and server2 share a subnet, their traffic is switched
at layer 2 and never reaches a pfSense interface, so pfSense cannot filter it. pfSense is therefore
the perimeter firewall only. It governs traffic that crosses the perimeter, not traffic between the
two servers.

This is a property of the topology, not of the pfSense configuration. No rule on the appliance can
compensate for it, because the packets never arrive there.

## The two implemented layers

The east-west position is enforced by two layers that do not depend on pfSense.

| Layer | Mechanism                   | Intent                                               |
| ----- | --------------------------- | ---------------------------------------------------- |
| 1     | Authentik bound to loopback | A compromised app cannot reach the identity provider |
| 2     | Guest nftables on both VMs  | Default-deny between the VMs, with logged drops      |

Layer 1: Authentik listens on loopback. Only the reverse proxy on the same host can reach it, so an
application container that is compromised on either VM has no network path to the identity provider.

Layer 2: a guest nftables ruleset on server1 and on server2, applying default-deny to inbound
traffic on the inter-server path, with rate-limited drop logging. Dropped packets are logged with
the `nft-drop` prefix and counted into the daily digest.

### Intent of each ruleset

| Host    | Accepts                                                       |
| ------- | ------------------------------------------------------------- |
| server1 | 443 and SSH from the user LAN; 9000 and 9443 on loopback only |
| server2 | App ports from server1; SSH from server1 or the user LAN      |

On server2, the only host that may open an application port is server1, the reverse proxy. Syncthing
sync ports are reachable from the tailnet and from nowhere else; they are not exposed to the user
LAN and not exposed to server1.

On server1, port 443 accepts the user LAN subnet, which is the single ingress described in
`docs/exposure-model.md`. Ports 9000 and 9443 are bound to loopback for the identity provider, so
they are not reachable across the inter-server path at all. SSH is scoped to the user LAN for now
and is scheduled to move to the tailnet.

### Ruleset files

The rulesets are templates in this repository, not live configuration:

| Host    | File                        |
| ------- | --------------------------- |
| server1 | `docs/nftables-server1.nft` |
| server2 | `docs/nftables-server2.nft` |

Both are comment-heavy, put every address in a `define`, and use RFC 5737 documentation addresses as
placeholders. Replace the defines with the real subnets and read the whole file before loading it.

### Docker-published ports and the input chain

Docker publishes a container port by writing a DNAT rule, and the packet is then forwarded to the
container. It never crosses the input chain, so input rules alone cannot express "this published port
accepts traffic from the proxy host only". A ruleset that only has an input chain gives a false sense
of protection here.

Both rulesets therefore carry a second chain, `prerouting`, with `type filter hook prerouting priority
raw`. That hook runs before the `nat` hook where Docker's DNAT lives, so the destination port is still
the published port as the client wrote it. That ordering is what makes the rule correct, and it means
the control is declarative: it reloads with the rest of the file and does not depend on Docker's chain
state or on iptables compatibility.

Matching is on `daddr = BIND_ADDR` rather than on an ingress interface, so it cannot interfere with
container egress, which has a different destination.

The equivalent alternative is the `DOCKER-USER` chain, managed through the `iptables-nft` frontend.
It is not used: it has to be re-applied after Docker restarts, and mixing an iptables-managed chain
with a declarative nftables file is one more thing to get wrong at 2am.

Neither approach requires touching Docker's own `DOCKER`, `DOCKER-USER` or `DOCKER-ISOLATION` chains,
and neither file does. Both nftables files carry this caveat in their own comments.

## Accepted residual risks

These are known and accepted. Each is a deliberate trade, not an oversight.

| Risk                                             | Reason accepted                                           |
| ------------------------------------------------ | --------------------------------------------------------- |
| Rooted guest bypasses its own nftables           | Out-of-band enforcement costs bandwidth; see mitigations. |
| No east-west prevention survives host compromise | Container escape is the hard step; layers stop below it.  |
| Authentik downtime blocks Nextcloud/Immich login | Deliberate trade; break-glass admin in each app.          |
| Nextcloud AIO keeps a read-write Docker socket   | AIO requires it to spawn its own containers.              |
| Operator laptop retains firewall-wide access     | Until SSH moves to the tailnet.                           |

A rooted guest can rewrite its own ruleset, so layer 2 is not a boundary against a host that is
already fully compromised. Out-of-band enforcement would be the answer, but it costs either
bandwidth or complexity, so the risk is carried. The mitigations that keep it small are: loopback
binds for the identity provider, as few published ports as the services allow, `cap_drop: ALL`,
`no-new-privileges`, VPN-only reachability for the sensitive services, and drop logging so that a
failed attempt is visible.

No east-west prevention survives a full host compromise. Container escape is the hard step, and the
two layers stop everything below it. Nextcloud AIO keeps a read-write Docker socket because AIO
requires it to spawn its own containers; that is an accepted consequence of the AIO deployment
model, not an oversight. The operator laptop keeps firewall-wide access until SSH moves to the
tailnet, which is a scheduling item rather than a design decision.

## Telemetry

Drop logging is the only east-west telemetry available. There is no flow data between the VMs,
because the traffic does not pass a device that could export it.

The signal to watch is a blocked connection from server2 to an unexpected port on server1. Normal
server2 traffic goes to server1 only for the proxied application ports; a drop toward any other port
means either a misconfiguration or an application attempting to reach something it should not. Drops
counted in the daily digest are therefore treated as an alert, not as noise.

## Considered and not implemented

| Option                  | Status      | Reason                                                             |
| ----------------------- | ----------- | ------------------------------------------------------------------ |
| Proxmox VM firewall     | Not adopted | Declined for simplicity.                                           |
| pfSense re-segmentation | Not adopted | Inter-VM bulk transfers would go on the wire; pfSense is physical. |

Re-segmentation would place the two VMs on separate networks with pfSense routing between them. That
makes the appliance a filtering point, but it also puts every inter-VM bulk transfer on the wire,
including backups and media movement that are currently switched locally at line rate. For the
present workload the bandwidth cost outweighs the filtering gain.

The Proxmox VM firewall would give a host-level ruleset per VM and is a viable future layer. It was
declined for simplicity: it duplicates the guest rulesets and adds a second place to keep the same
policy correct.

Both remain revisit options. Revisit re-segmentation if inter-VM data volume stops mattering, and the
Proxmox firewall if the guest rulesets become hard to maintain or need a fallback that survives a
compromised guest.
