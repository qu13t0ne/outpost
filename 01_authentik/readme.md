# Authentik

**About:** "authentik is an open-source Identity Provider focused on flexibility and versatility."
| <https://goauthentik.io/docs/> |

**Role in this stack:** the single source of identity for services that support OIDC. It is not a
proxy-side gate. Nothing in this repository uses `forward_auth`, and the proxy outpost is deliberately
not configured. The reasoning is in [the exposure model](../docs/exposure-model.md) and the wiring is
in [the OIDC runbook](../docs/authentik-oidc.md).

**Tier:** VPN. The IdP must never be reachable from the internet.

## Prerequisites and assumptions

- Runs on **server1**, next to Caddy, not on the application host. Two reasons: the proxy rarely needs
  to reach a different host to authenticate a request, and the IdP stays up when the app host does not.
- Joined to the `outpost` external docker network so Caddy can reach it by name. Create that network
  once on server1: `docker network create outpost`.
- Reached only through Caddy at `auth.<domain>`. Ports are bound to loopback, never to the LAN.
- No Docker socket is mounted anywhere in this stack. Authentik's embedded outpost needs no socket,
  and the separate-container outpost integration is not used. A writable socket would give the IdP
  root on its host for no benefit.

## Services

| Service      | Purpose                                          |
| ------------ | ------------------------------------------------ |
| `server`     | Web UI, API, and the embedded outpost            |
| `worker`     | Background tasks, outbound email, scheduled work |
| `postgresql` | Persistent database                              |
| `redis`      | Cache and task queue                             |

## Setup

### 1. Environment

Copy `.env.example` to `.env` and edit:

| Variable               | Notes                                                              |
| ---------------------- | ------------------------------------------------------------------ |
| `CONFIG_PATH`          | Host directory for media, templates and certs                      |
| `TZ`                   | Timezone for the containers                                        |
| `PG_DB`, `PG_USER`     | Database name and user                                             |
| `PG_PASS`              | Generate: `openssl rand -hex 32`                                   |
| `AUTHENTIK_SECRET_KEY` | Generate: `openssl rand -hex 32`. Rotating it invalidates sessions |
| `AUTHENTIK_IMAGE`      | Registry and repository                                            |
| `AUTHENTIK_TAG`        | Pin the version. Do not track `latest`                             |
| `COMPOSE_PORT_HTTP`    | Loopback port for the web UI, used by Caddy                        |
| `COMPOSE_PORT_HTTPS`   | Loopback port for the HTTPS listener, used by Caddy                |

`PG_PASS` and `AUTHENTIK_SECRET_KEY` are required: the compose file uses `${VAR:?}`, so the stack
refuses to start without them rather than falling back to a default.

### 2. Start

```
docker compose up -d
```

Then complete the initial setup flow at `https://auth.<domain>/` to set the `akadmin` password and
store it in the password manager.

### 3. Reverse proxy

`Caddyfile` on server1. Note that this block belongs on the LAN/VPN listener only: no Cloudflare
Tunnel ingress rule may exist for this hostname.

```
auth.{$DOMAIN} {
    import use_tls
    import errorHandling

    reverse_proxy authentik:9000
}
```

If Caddy is on a different host than Authentik, publish `COMPOSE_PORT_HTTP` on the host address
instead of loopback and proxy to it, and add that port to the application host's ruleset.

## Backup and restore

- Database: `docker exec -t <postgres-container> pg_dumpall -U <user> > authentik-db.sql`
- Media: `$CONFIG_PATH/media`
- Templates: `$CONFIG_PATH/custom-templates`
- Certs: `$CONFIG_PATH/certs`
- The `.env` file, which is gitignored and holds `AUTHENTIK_SECRET_KEY`

Restore the database before starting the stack. A restore without `AUTHENTIK_SECRET_KEY` keeps working
for new logins but invalidates every existing session, so restore both together.

## Troubleshooting

| Symptom                      | Check                                                                    |
| ---------------------------- | ------------------------------------------------------------------------ |
| Stack will not start         | `PG_PASS` and `AUTHENTIK_SECRET_KEY` are set and non-empty               |
| 502 from Caddy               | Authentik is on the `outpost` network and the container name resolves    |
| Login loop in an application | Issuer URL trailing slash, redirect URI exact match, app host clock skew |
| Emails not sent              | The worker sends outbound mail; it needs SMTP configured in the admin UI |

## Resources

- <https://goauthentik.io/docs/>
- <https://docs.goauthentik.io/integrations/services/nextcloud/>
- <https://docs.goauthentik.io/integrations/services/immich/>
