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

Caddy itself is set up to receive and proxy traffic from both the Tunnel container and from 443 on the localhost, allowing direct access to services from the local network without having to hairpin traffic through the Internet/Cloudflare.
This also allows some URLs to be designated *local_only*, which (with the requisite Caddyfile configuration) permits traffic from the local network but blocks anything coming from Cloudflare and/or non-approved IP addresses.

## Setup

### Summary

- Copy `template-Caddyfile` to `Caddyfile`
- Copy `template-env` to `.env`
- Get Cloudflare API token
- Edit `.env`
- Edit `Caddyfile` to add config for desired sites and services
- Follow additional setup instructions that follow

### Cloudflare Setup Part 1

#### Get Cloudflare API Token for DNS ACME Cert Generation

Create an API token in Cloudflare for Caddy to authenticate and perform the necessary DNS verifications.
Copy or leave this page open, you'll need it in the next step.
- Ref [this documentation page](https://caddyserver.com/docs/modules/dns.providers.cloudflare) and [this article](https://samjmck.com/en/blog/using-caddy-with-cloudflare/#using-a-lets-encrypt-certificate) as needed.

#### Create Cloudflare Tunnel

- Create a Cloudflare Tunnel through the Cloudflare Dash Zero Trust UI at https://one.dash.cloudflare.com.
- Copy the token it gives you. The easiest way to do this is to copy the *Run* command it gives you into a temporary text file. The full token isn't displayed in the UI. We'll need this in a second.

### Configure .env file

- Create a `.env` file from the included [template_env](./template_env).
- Edit the contents as appropriate and indicated in the file.
- Make the following changes to the template:
  - Add email for cert generation & renewal notifications
  - Add the Cloudflare API token generated in the previous step
  - Add the Cloudflare Tunnel token generated in the previous step
  - Create a `JWT_SHARED_TOKEN` using a random alphanumeric string generator such as [this](https://www.grc.com/passwords.htm).

### Create Caddyfile

- Copy `template_Caddyfile` to `Caddyfile`

### Edit Caddyfile

For initial testing, make sure the Caddyfile is as follows:
- Make sure the `debug` line is uncommented
- Make sure the line for the Let's Encrypt staging URL is uncommented

### Starting & Managing Containers

Start the containers with the standard `docker compose up -d` command.

To reload the Caddy container after Caddyfile edits, it is easiest to just restart the container (`docker compose restart caddy`).

Alternately, the following command reloads caddy config after changes to the Caddyfile.
```
docker exec -w /etc/caddy caddy caddy reload
```
Any other `caddy` commands can be run in the container by replacing `reload` above with the relevant command.

## Backup and Restore

### Backup

- Include this entire directory in backups.
- Include the APPDATA directory defined in the *.env* file, if pointing elsewhere

### Restore

- Replace relevant directory(ies) from backup.
- Launch container.

## Resources

- https://caddyserver.com/
- https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2
- https://github.com/cloudflare/cloudflared
- https://hub.docker.com/r/cloudflare/cloudflared
