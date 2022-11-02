# RETIRED - WILL NOT WORK
**Nextcloud AIO requires deal-breaker permissions schema for mounting local folders in the container. While this would work if it were the only service on the host and not using NFS shares, it will not work in my context. Transitioning to a more traditional Nextcloud Docker setup.**

# Nextcloud AIO (Documents and Collaboration Platform)

**About:** Nextcloud AIO stands for Nextcloud All In One and provides easy deployment and maintenance with most features included in this one Nextcloud instance. Nextcloud offers the industry-leading, on-premises content collaboration platform. Our technology combines the convenience and ease of use of consumer-grade solutions like Dropbox and Google Drive with the security, privacy and control business needs.\
**Default Subdomain:** `nextcloud.domain.tld` \
**AIO Admin Interface:** `ncadmin.domain.tld`

## Setup

- Copy `template-env` to `.env`
- Review `.env` and make any changes as needed
	- Ensure appropriate permissions have been applied to the ...
- Launch the master container with `docker compose up -d`
- Access the AIO administration startup page at `ncadmin.domain.tld`
- Copy/write down/safely store the password shown there (a string of words)
	- *Password will not be shown again!*
- Click the button to open the Nextcloud AIO login and log in with the provided password
- Review & set the *Optional addons* and *Timezone change*
- Click the 'Start Containers' button to create and start all included containers
- Wait until all containers are 'Running' with a green indicator.
	- This can take a few minutes.
	- Troubleshoot any issues as needed by clicking the 'Starting' link next to the containers to view logs & error info.

## Backup

- #TODO

## Resources

- https://nextcloud.com/
- https://github.com/nextcloud/all-in-one
