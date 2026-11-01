# Immich

- **About:** "Self-hosted photo and
video management solution. Easily back up, organize, and manage your photos on your own server. Immich helps you browse, search and organize your photos and videos with ease, without sacrificing your privacy."
- **Default Port:** 2283

## Setup

Follow the Docker Compose instructions from Immich documentation: https://docs.immich.app/install/docker-compose

- Download docker-compose.yml and example.env by running the following commands:

```sh
wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env
```

- In the `.env` file, adjust locations for the following as desired:
  - UPLOAD_LOCATION
  - DB_DATA_LOCATION
  - TZ
  - IMMICH_VERSION
  - DB_PASSWORD

## Bind the published port

`immich/docker-compose.yml` is in `.gitignore`, deliberately: it is the vendor's file and it is
replaced on every upgrade. That makes the bind a step in this procedure rather than a fact in the
repository, and it is the one place where a wildcard port can reappear without anyone editing
anything.

After downloading the compose file, replace the published port. The line to find looks like
`      - '2283:2283'` and the line it becomes is:

```yaml
      - "${BIND_ADDR}:2283:2283"
```

Then confirm, from the same directory:

```sh
grep -n '2283' docker-compose.yml
docker compose config | grep -A2 'published: "2283"'
```

`BIND_ADDR` is the host's LAN address, the shared per-host fact in `outpost.env` that the other service
directories use. The
result must be one address, never `0.0.0.0` and never bare `2283:2283`. Re-apply this after every
Immich upgrade, and check it with `ss -lntp | grep 2283` before calling the upgrade done.

## Resources

- https://docs.immich.app/install/docker-compose
