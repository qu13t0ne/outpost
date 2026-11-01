# Template Files

**About:** Template files for creating new services.

## Setup

- Copy this folder to a new path with the name of the service.
- Move `template-readme.md` to `readme.md`
- Edit `docker-compose.yml`, `readme.md`, and `.env.example` as needed. The `.env.example` is the
  seed for the new service's `config.example/<service>/` entry;
  see [the configuration model](../docs/config-model.md).