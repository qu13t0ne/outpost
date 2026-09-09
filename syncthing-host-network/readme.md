# Syncthing Host-Network Variant

- **About:** Syncthing configured to run with host networking so the GUI and sync ports are governed by the host firewall.
- **Default ports:** 8384 (web UI), 22000 (sync), 21027 (local discovery)

## Setup

- Copy `template_env` to `.env` and edit it for your host.
- Set `PUID` and `PGID` to match the owner of the vault directory on disk.
- Set `CONFIG_PATH` to the local Syncthing config directory you want on the host.
- Set `VAULT_PATH` to the actual local filesystem path for the vault share on the host.
- Start the container with `docker compose up -d` from this folder.

## Networking

This variant uses `network_mode: host`, so Syncthing listens on the host ports directly.

- Host firewall rules are the access control layer for these ports.
- GUI access (TCP 8384) should stay restricted to the proxy host IP only.
- Do not publish Docker bridge ports for this variant.

## Reachability Modes

### 1. LAN-only sync

Most restrictive option.

- Allow TCP 22000, UDP 22000, and UDP 21027 from your LAN/admin subnet only, for example `192.168.x.0/24`.
- Deny or drop otherwise.

No router port forwarding is needed. Devices off your physical network cannot sync until they are back on LAN, or on a future VPN.

### 2. Open sync across the internet

- Allow TCP 22000, UDP 22000, and UDP 21027 from `0.0.0.0/0`.
- Keep GUI access (TCP 8384) restricted to the Caddy or proxy VM IP only.

Router config:

- Port forward external TCP 22000, UDP 22000, and UDP 21027 to the host's LAN IP.

Risk, stated plainly:

- Anyone on the internet can reach and fingerprint the listening port as Syncthing.
- They cannot pair or pull data without your device ID. Syncthing uses TLS and device-ID pinning and rejects unrecognized devices by default.
- This makes the container the one internet-facing service on this box, so keep the image updated regularly.
- No compose or container changes are needed. `network_mode: host` already listens on these ports; this is purely firewall and router config.

### 3. Recommended follow-up: move to VPN-based sync

Once time allows, install a VPN mesh such as Tailscale on the host and remote devices. Then:

- Revert the firewall rule to LAN-subnet-only, but include the VPN subnet, for example `100.64.0.0/10`, or scope to specific VPN device IPs.
- Remove the router port forward from the open-sync state.
- Keep GUI access restricted to the proxy host IP only.

Result: the sync ports stay reachable without exposing them to the raw internet, while preserving the same Syncthing config.

## Firewall Rules Summary

Recommended access rules for a host-network deployment:

- TCP 8384: allow only from the reverse-proxy host.
- TCP 22000: use LAN-only, open internet, or VPN-scoped access depending on your chosen reachability mode.
- UDP 22000: use LAN-only, open internet, or VPN-scoped access depending on your chosen reachability mode.
- UDP 21027: use LAN-only, open internet, or VPN-scoped access depending on your chosen reachability mode.

Deny or drop all other sources for these ports.

## Reverse Proxy

Point Caddy at `http://<host-ip>:8384` and keep the host-header override in place:

```caddy
syncthing.domain.tld {
    import use_tls
    import errorHandling

    reverse_proxy <host-ip>:8384 {
        header_up Host {upstream_hostport}
    }
}
```

## Backup

- Back up the `CONFIG_PATH` directory with the rest of your Syncthing configuration.
