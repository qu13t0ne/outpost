# Budibase (Low Code Platform)

**About:** Low code platform for creating internal tools, workflows, and admin panels in minutes. \
**Default Subdomain:** `budibase.domain.tld`

## Setup

- Create `.env` file from `template-env`. Fill in / update the required values.
- Start Containers

## Caddy
Add the following to the Caddyfile
```
########## BUDIBASE
budibase.{$DOMAIN1} {
	 import use_tls
	 route {
		 reverse_proxy budibase:10000
	 }
 }
```

## Backup

- #TODO

## Resources

- https://budibase.com
- https://docs.budibase.com/docs/docker-compose
