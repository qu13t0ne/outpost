# Caddy (Reverse Proxy)

## Key Commands

### Reload Caddy Config

The following command reloads caddy config after changes to the Caddyfile.
```
docker exec -w /etc/caddy caddy caddy reload
```
Any other `caddy` commands can be run in the container by replacing `reload` above with the relevant command.

## Setup

**Notes:**
- This setup assumes using Cloudflare as nameserver & DNS management for your domain. Thus, the Cloudflare DNS module is included in the Dockerfile build for this Caddy instance and the Caddyfile is configured to use a Cloudflare API key.
- The Acme DNS challenge is enabled for TSL certificate generation. TLS certificates can therefore be generated for sites and services that are not internet-routable (i.e. internal-only sites). This is not possible if using the HTTP challenge.

### Create new docker network

```
docker network create proxy_net
```

### Set up Cloudflare DNS ACME Cert Generation

- Set up DNS records in Cloudflare for your domain, as shown below. This creates a primary `A` record for the domain and a wildcard `CNAME` record for first-level subdomains. Start by leaving proxy disabled, as it simplifies any initial troubleshooting. Once certs are generating and sites are routing successfully, proxy can be enabled.

| **Type** | **Name**   | **Content** | **Proxy Status** |
|----------|------------|-------------|------------------|
| A        | {MyDomain} | {ServerIP}  | Disabled         |
| CNAME    | *          | {MyDomain}  | Disabled         |

- Create an API token in Cloudflare for Caddy to authenticate and perform the necessary DNS verifications. Copy or leave this page open, you'll need it in the next step.
  - Ref [this documentation page](https://caddyserver.com/docs/modules/dns.providers.cloudflare) and [this article](https://samjmck.com/en/blog/using-caddy-with-cloudflare/#using-a-lets-encrypt-certificate) as needed.

### Configure .env file

Create a `.env` file using the template below.
```shell
DOCKER_MY_NETWORK=proxy_net

# ROUTING & TLS CONFIG
MY_DOMAIN=domain.tld
EMAIL_FOR_ACME=replace_me
CF_API_TOKEN=replace_me

# CADDY SECURITY CONFIG
JWT_SHARED_TOKEN=replace_me
```

Make the following changes to the template:
- Add relevant domain name as `MY_DOMAIN`
- Add email for cert generation & renewal notifications
- Paste the Cloudflare API token generated in the previous step
- Create a `JWT_SHARED_TOKEN` using a random alphanumeric string generator such as [this](https://www.grc.com/passwords.htm).

### Basic Functionality Tests

#### Edit Caddyfile
For initial testing, make sure the Caddyfile is as follows:
- Uncomment `debug`
- Uncomment Let's Encrypt staging URL
- Uncomment all sites in the `Initial Caddy Testing` section, i.e.
  - `test1.{$MY_DOMAIN}`
  - `test2.{$MY_DOMAIN}`
  - `test3.{$MY_DOMAIN}`

#### Stand up the containers
Stand up the Caddy container as well as two test containers, `whoami` and `nginx`.
```
docker compose up -d
docker compose -f whoami-compose.yml up -d
docker compose -f nginx-compose.yml up -d
```

Monitor Caddy logs for successful generation of TLS certs. (Not applicable if domain is `localhost`.)
```
docker logs caddy -f
```

In your browser (suggestion: use a *Private Browsing* window to avoid caching issues), navigate to the `test1`, `test2`, and `test3` subdomains. Depending on the browser, you may need to click through some warning messages about untrusted certificates, since at this point you're still using the Let's Encrypt Staging server for certificate generation. This is expected. The goal here is to make sure all three sites are successfully routable.
- `test1` ==> "Hello, World!"
- `test2` ==> whoami container
- `test3` ==> nginx container

#### Enable Cloudflare Proxy

In Cloudflare, edit the DNS records created above to change Proxy Status to 'proxied'. 

Retest all three sites.

Use `Ctrl+C` to stop watching the Caddy logs if you haven't done so already.

#### Switch to Production TLS Certificates

Assuming all of the above steps worked, edit the `Caddyfile` to comment out the Let's Encrypt Staging URL.

Take down the Caddy container, delete generated `config/` and `data/` directories to ensure you get new production certs, and restart the container.

```shell
docker compose down
sudo rm -rf config/ data/
docker compose up -d
```
Watch the Caddy logs if desired. 

Use a new Private Browsing instance to try the three test sites again.

#### Testing Cleanup

Disable test containers. 
```
docker compose -f whoami-compose.yml down
docker compose -f nginx-compose.yml down
```

Comment out the initial Caddy testing config in the `Caddyfile` and the `debug` setting, then reload it.

## Caddy Security

### Retrieve Initial Password to webadmin User

The root user created during initial setup is `webadmin`. The password is automatically generated and saved to the Docker logs. To retrieve it for initial login, use the following command:
```
docker logs caddy 2>&1 | grep webadmin
```

The output will look something like the below example. Look for the `secret`.
```
{"level":"info","ts":1664823133.2475781,"logger":"security","msg":"created default admin user for the database","username":"webadmin","email":"webadmin@localdomain.local","secret":"028bac75-56a6-44e2-85c8-807db94f446a","roles":["authp/admin"]}
```

**Change this auto-generated password!** Use the *Portal Settings* link on the authentication portal page.

Alternately, the password can be changed by updating the bcrypt hash in the `users.json` file.

### Adding Users

New users must be added manually to the file `./caddy/data/auth/users.json` in the following format:

```json
    {
      "id": "<Enter UUID>",
      "username": "<Enter Username>",
      "email_address": {
        "address": "<Enter Email>",
        "domain": "localdomain.local"
      },
      "email_addresses": [
        {
          "address": "<Enter Email>",
          "domain": "localdomain.local"
        }
      ],
      "passwords": [
        {
          "purpose": "generic",
          "algorithm": "bcrypt",
          "hash": "<Enter Password Hash>",
          "cost": 10,
          "expired_at": "0001-01-01T00:00:00Z",
          "created_at": "2022-10-02T11:56:19.940780255Z",
          "disabled_at": "0001-01-01T00:00:00Z"
        }
      ],
      "created": "2022-10-01T18:49:54.966047725Z",
      "last_modified": "2022-10-02T11:56:20.00895137Z",
      "revision": 1,
      "roles": [
        {
          "name": "user",
          "organization": "authp"
        }
      ]
    }
```

Where:
- `<Enter UUID>` = Generate a version 4 UUID at https://www.uuidgenerator.net/
- `<Enter Username>` and `<Enter Email>` = Enter user info
- `<Enter Password Hash>` = Generate a bcrypt hash for the user password at https://bcrypt.online or through any other preferred method. Use *Cost Factor* of 10.

All of this JSON can be created using the script [generateUserConfig.sh](./generateUserConfig.sh).

Whenever the `users.json` file is updated, reload Caddy to apply the changes.

## Resources

- https://caddyserver.com/
- https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2
- https://authp.github.io/