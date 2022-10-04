# Caddy Reverse Proxy

## Key Commands

### Reload Caddy Config

The following command reloads caddy config after changes to the Caddyfile.
```
docker exec -w /etc/caddy caddy caddy reload
```

## Initial Setup

### Create new docker network

```
docker network create proxy_net
```

### Configure .env file

Create a `.env` file using the template below.
```
MY_DOMAIN=localhost
DOCKER_MY_NETWORK=proxy_net
CADDY_VERSION=2
JWT_SHARED_TOKEN=123456789
```
#TODO UPDATE THIS

Make the following changes to the template:
- Add relevant domain name as `MY_DOMAIN`
- Update `CADDY_VERSION` as appropriate
- Create a `JWT_SHARED_TOKEN` using a random alphanumeric string generator such as [this](https://www.grc.com/passwords.htm).


### Basic Functionality Test

Stand up the Caddy container as well as two test containers, `whoami` and `nginx`. Ensure the `Initial Caddy Testing` section in the `Caddyfile` is uncommented before proceeding.
```
docker compose up -d
docker compose -f whoami-compose.yml up -d
docker compose -f nginx-compose.yml up -d
```

Monitor Caddy logs for successful generation of TLS certs. (Not applicable if domain is `localhost`.)
```
docker logs caddy
```

Once the test is successful, disable test containers. Comment out the relevant config in the `Caddyfile` and reload it.
```
docker compose -f whoami-compose.yml down
docker compose -f nginx-compose.yml down
```

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

## References

- https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2
- https://authp.github.io/