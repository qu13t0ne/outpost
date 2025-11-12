# Immich

- **About:** "Self-hosted photo and
video management solution. Easily back up, organize, and manage your photos on your own server. Immich helps you browse, search and organize your photos and videos with ease, without sacrificing your privacy."
- **Default Port:** 2283

## Setup

Follow the Docker Compose instructions from Immich documentation: https://docs.immich.app/install/docker-compose

- Download docker-compose.yml and example.env by running the following commands:

```sh
wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env
```

- In the `.env` file, adjust locations for the following as desired:
  - UPLOAD_LOCATION
  - DB_DATA_LOCATION
  - TZ
  - IMMICH_VERSION
  - DB_PASSWORD

## Resources

- https://docs.immich.app/install/docker-compose
