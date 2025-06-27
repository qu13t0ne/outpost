# Nextcloud

- **About:** The flexible open source file synchronization and sharing solution.

## Info

- Uses Nextcloud All-In-One (AIO), "The official Nextcloud installation method. Provides easy deployment and maintenance with most features included in this one Nextcloud instance."

## Setup

### Initial

- Copy `template-env` to `.env`
- Update `.env` as required
- Docker compose up
- Follow the mastercontainer instructions and startup process (first time)

### Caddyfile

```
cloud.domain.tld {
  reverse_proxy <ip>:11000
}
```

## Recommended Nextcloud Apps

### Security

For better MFA:
- Two-Factor TOTP Provider
- Two-Factor WebAuthn
- Two-Factor Admin Support

For additional security benefits:
- Auditing/Logging
- Brute Force Settings
- Suspicious Login

### Files and Storage
- External Storage Support
- File Sharing

<!-- ### Media -->
<!-- - Photos -->
<!-- - Preview Generator -->
<!--   - After installing and enabling the app, run `docker exec -u 33 -it nextcloud-app php occ preview:generate-all` to begin generating image previews. (**May take a while, depending on size of image directory!**) -->
<!--   - On the host system, schedule a cron job to run regularly and pre-generate previews. See example in the next section. -->
<!---->
<!-- ## Cron Jobs -->
<!---->
<!-- Set up the following cron jobs on the host system. Modify the schedules as needed. -->
<!-- 1) Regularly scan the file system, including external storage, for file updates and changes -->
<!-- ``` -->
<!-- 0,15,30,45 * * * * docker exec -u 33 -it nextcloud-app php occ files:scan --all     # nextcloud rescan files and external storages -->
<!-- ``` -->
<!-- 2) Pre-generate image previews -->
<!-- ``` -->
<!-- 5,20,35,50 * * * * docker exec -u 33 -it nextcloud-app php occ preview:pre-generate # nextcloud preview generator app -->
<!-- ``` -->

## Resources

- https://github.com/nextcloud/all-in-one/blob/main/compose.yaml
- https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md#inspiration-for-a-docker-compose-file
- https://github.com/nextcloud/all-in-one/
- https://nextcloud.com/blog/how-to-install-the-nextcloud-all-in-one-on-linux/
