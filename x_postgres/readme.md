## PostgreSQL and pgAdmin (Relational Database + Administration Portal)

**About:** "The World's Most Advanced Open Source Relational Database" +  "The most popular and feature rich Open Source administration and development platform for PostgreSQL" \
**Default Subdomain:** `pgadmin.domain.tld`

## Setup

### .env File
Create `.env` file using the following template. Fill in / update the required values.
```
DOCKER_MY_NETWORK=proxy_net

POSTGRES_USER=yourUser
POSTGRES_PW=changeit
PGADMIN_MAIL=your@email.com
PGADMIN_PW=changeit

# Below can be left as default db name or changed
POSTGRES_DB=postgres
```

### Start Containers

```shell
docker compose up -d
```

### Verify Caddy Config
If using the default [Caddy](../caddy/readme.md) config, the [Caddyfile](../caddy/Caddyfile) will default to subdomain `pgadmin.$MY_DOMAIN` for this app. Ensure the relevant block is uncommented in the Caddyfile, and update it as needed.

### Add PostgreSQL database to pgAdmin
Log into the pgAdmin interface using the credentials from the `.env` file. Then add the postgres container and initial database to pgAdmin.

1. Right-click "Servers" in the top-left corner and select "Create" -> "Server..."
2. Name your connection
3. Change to the "Connection" tab and add the connection details:
	- Hostname: "postgres" (this would normally be your IP address of the postgres database - however, docker can resolve this container ip by its name)
	- Port: "5432"
	- Maintenance Database: $POSTGRES_DB (see .env)
	- Username: $POSTGRES_USER (see .env)
	- Password: $POSTGRES_PW (see .env)


## Backup

- #TODO

## Resources
- https://github.com/docker/awesome-compose/tree/master/postgresql-pgadmin
- https://www.postgresql.org/
- https://hub.docker.com/_/postgres
- https://www.pgadmin.org/
- https://www.pgadmin.org/docs/pgadmin4/latest/container_deployment.html