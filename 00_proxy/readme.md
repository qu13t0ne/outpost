# Reverse Proxy

**About:**
- **Caddy:** "Caddy 2 is a powerful, enterprise-ready, open source web server with automatic HTTPS written in Go" | https://caddyserver.com/docs/
- **Cloudflared:** "Command-line client for Cloudflare Tunnel, a daemon that proxies traffic from the Cloudflare network to your origins" | https://github.com/cloudflare/cloudflared

## Prerequisites and Assumptions

- This setup assumes using Cloudflare as nameserver & DNS management for your domain(s). Thus, the Cloudflare DNS module is included in the Dockerfile build for this Caddy instance and the Caddyfile is configured to use a Cloudflare API key.
- Cloudflare Tunnel will be set up to reverse proxy Internet traffic to this local hosting server. This allows Internet access to designated sites without needing to deal with NAT, dynamic DNS, or edge firewall changes.
  - Note: Cloudflare Tunnel management is through the Cloudflare UI at https://one.dash.cloudflare.com
- The Acme DNS challenge is enabled for TLS certificate generation. TLS certificates can therefore be generated for sites and services that are not internet-routable (i.e. internal-only sites). This is not possible if using the HTTP challenge.

## Description

The docker-compose file includes the following linked containers:
- Caddy container, which will serve as the reverse proxy for all internal sites and services and will manage TLS certificate generation and renewal
- Tunnel container running Cloudflared, which tunnels Internet traffic to the caddy container for further proxying to the appropriate target

Caddy itself is set up to receive and proxy traffic from both the Tunnel container and from 443 on the host LAN address, allowing direct access to services from the local network without having to hairpin traffic through the Internet/Cloudflare.
Reachability decides the tier, not a check inside a site block: a hostname that the tunnel does not
route is reachable only from the tailnet or the LAN, and a tunnel-exposed hostname is gated by a
Cloudflare Access policy on the tunnel. See [the exposure model](../docs/exposure-model.md).

## Setup

### Summary

- Run `just init` to create `$OUTPOST_CONFIG_DIR/` from `config.example/`
- Get the Cloudflare API token and the Cloudflare Tunnel token
- Edit the proxy config: `outpost.env` (`BIND_ADDR`, `TAILSCALE_ADDR`, `APPDATA`),
  `00_proxy/app.env` (the tokens, `EMAIL_FOR_ACME` and `DOMAIN`), and `00_proxy/Caddyfile` for the
  desired sites and services
- Follow additional setup instructions that follow

### Cloudflare Setup Part 1

#### Get Cloudflare API Token for DNS ACME Cert Generation

Create an API token in Cloudflare for Caddy to authenticate and perform the necessary DNS verifications.
Copy or leave this page open, you'll need it in the next step.
- Ref [this documentation page](https://caddyserver.com/docs/modules/dns.providers.cloudflare) and [this article](https://samjmck.com/en/blog/using-caddy-with-cloudflare/#using-a-lets-encrypt-certificate) as needed.

#### Create Cloudflare Tunnel

- Create a Cloudflare Tunnel through the Cloudflare Dash Zero Trust UI at https://one.dash.cloudflare.com.
- Copy the token it gives you. The easiest way to do this is to copy the *Run* command it gives you into a temporary text file. The full token isn't displayed in the UI. We'll need this in a second.

### Configure the proxy config

- `just init` placed the proxy's config under the resolved directory (`$OUTPOST_CONFIG_DIR`), never
  in the tree: `outpost.env` for the shared per-host facts, `00_proxy/app.env` for the tokens and
  Caddy application config, and `00_proxy/Caddyfile` for the site blocks.
  See [docs/config-model.md](../docs/config-model.md).
- Edit the contents as appropriate and indicated in the files.
- Make the following changes:
  - In `outpost.env`, set `BIND_ADDR` (this host's LAN address) and `TAILSCALE_ADDR` (from `tailscale ip -4`).
  - Add the email for cert generation & renewal notifications as `EMAIL_FOR_ACME` in `00_proxy/app.env`.
  - Add the Cloudflare API token generated in the previous step as `CF_API_TOKEN` in `00_proxy/app.env`.
  - Add the Cloudflare Tunnel token generated in the previous step as `TUNNEL_TOKEN` in
    `00_proxy/compose.env` (it is interpolated into the tunnel command at start time, so it
    belongs in the interpolation pool, not `app.env`).
  - Create a `JWT_SHARED_TOKEN` using a random alphanumeric string generator such as [this](https://www.grc.com/passwords.htm).

### The Caddyfile

- `just init` placed the Caddyfile at `$OUTPOST_CONFIG_DIR/00_proxy/Caddyfile`, which the compose file
  mounts into the container. Edit it there.

### Edit Caddyfile

For initial testing, make sure the Caddyfile is as follows:
- Leave the `debug` line commented. It is for temporary troubleshooting only and logs headers
  and bodies for every site.
- Uncomment the Let's Encrypt staging URL while testing, then comment it again for production.

### Starting & Managing Containers

Start the containers with `just up 00_proxy`, which feeds the resolved config to docker compose.

To reload the Caddy container after Caddyfile edits, it is easiest to just restart the container (`docker compose restart caddy`).

Alternately, the following command reloads caddy config after changes to the Caddyfile.
```
docker exec -w /etc/caddy caddy caddy reload
```
Any other `caddy` commands can be run in the container by replacing `reload` above with the relevant command.

## Backup and Restore

### Backup

- Run `just backup 00_proxy` for the full checklist; it names the config directory paths, not a `.env`.
- Include the `APPDATA` directory defined in `outpost.env`, if pointing elsewhere

### Restore

- Run `just restore 00_proxy` for the checklist; it names the config directory paths.
- Replace the relevant directory(ies) from backup, and launch the container with `just up 00_proxy`.

## Resources

- https://caddyserver.com/
- https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2
- https://github.com/cloudflare/cloudflared
- https://hub.docker.com/r/cloudflare/cloudflared
