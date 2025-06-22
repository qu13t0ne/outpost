# Portainer - Proxy on Remote Host

- **About:** Lightweight Docker management web UI.
- **Default Port:** 9443

> Portainer Community Edition is a lightweight service delivery platform for containerized applications that can be used to manage Docker, Swarm, Kubernetes and ACI environments. It is designed to be as simple to deploy as it is to use. The application allows you to manage all your orchestrator resources (containers, images, volumes, networks and more) through a ‘smart’ GUI and/or an extensive API.
> [Source](https://github.com/portainer/portainer)

*Note: If Caddy proxy is running on the same host, use [the other Portainer setup](../portainer/) instead of this one.*

## Setup

- Copy `template_env` to `.env` and edit as appropriate.
- Start container.

## Reverse Proxy

`Caddyfile`
```
portainer.domain.tld {
    reverse_proxy https://<host_ip>:9443 {
        transport http {
            tls_insecure_skip_verify
        }
    }
}
```

## Backup and Restore

### Backup

- Include this entire directory in backups.

### Restore

- Replace this entire directory from backup.
- Launch container.

## Resources

- https://portainer.io
- https://docs.portainer.io/
- https://github.com/portainer/portainer
- https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/portainer
