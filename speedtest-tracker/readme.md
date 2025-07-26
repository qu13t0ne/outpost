# Speedtest-Tracker

- **About:** "Speedtest Tracker is a self-hosted application that monitors the performance and uptime of your internet connection."
- **Default Port:** 8380

## Setup

- Copy `template_env` to `.env` and edit as appropriate.
- Start container.

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
