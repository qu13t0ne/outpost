# Speedtest-Tracker

- **About:** "Speedtest Tracker is a self-hosted application that monitors the performance and uptime of your internet connection."
- **Default Port:** 8380

## Setup

- Run `just init` to create `$OUTPOST_CONFIG_DIR/` from `config.example/`, then edit
  `speedtest-tracker/compose.env` (its `PORT` and `CONFIG_PATH`) and `app.env` (its settings and
  secrets, including `APP_KEY`). See [the configuration model](../docs/config-model.md).
- Start the container with `just up speedtest-tracker`.

## Reverse Proxy

`Caddyfile`
```
########## Speedtest Tracker
networkspeed.domain.tld {
    reverse_proxy <host_server>:8380
}
```

## Backup and Restore

### Backup

- Include this entire directory in backups.

### Restore

- Replace this entire directory from backup.
- Launch container.

## Resources

- https://github.com/alexjustesen/speedtest-tracker
- https://docs.speedtest-tracker.dev/
