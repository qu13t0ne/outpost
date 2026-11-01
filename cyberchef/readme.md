# CyberChef (Cyber Swiss Army Knife)

- **About:** "GCHQ CyberChef in a container. CyberChef is the Cyber Swiss Army Knife web app for encryption, encoding, compression and data analysis."
- **Default Port:** 8000

## Setup

- Run `just init` to create `$OUTPOST_CONFIG_DIR/` from `config.example/`, then edit
  `cyberchef/compose.env` (its `PORT`; `BIND_ADDR` is shared in `outpost.env`).
  See [the configuration model](../docs/config-model.md).
- Start the container with `just up cyberchef`.

## Reverse Proxy

`Caddyfile`
```
########## CYBERCHEF
cyberchef.domain.tld {
    reverse_proxy <server_ip>:8000
}
```

## Backup

None. All data is stored client-side. *That means you need to back up your own cyberchef recipes some other way!*

## Resources

- https://hub.docker.com/r/mpepping/cyberchef/
