# OUTPOST - A Self-Sufficient, Self-Hosted Cloud Setup
```
 ▄▄▄▄▄▄▄▄▄▄▄  ▄         ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
▐░█▀▀▀▀▀▀▀█░▌▐░▌       ▐░▌ ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀  ▀▀▀▀█░█▀▀▀▀ 
▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌     ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌               ▐░▌     
▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌     ▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄▄▄      ▐░▌     
▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌     ▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌     ▐░▌     
▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌     ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌       ▐░▌ ▀▀▀▀▀▀▀▀▀█░▌     ▐░▌     
▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌     ▐░▌          ▐░▌       ▐░▌          ▐░▌     ▐░▌     
▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌     ▐░▌     ▐░▌          ▐░█▄▄▄▄▄▄▄█░▌ ▄▄▄▄▄▄▄▄▄█░▌     ▐░▌     
▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░▌     ▐░▌          ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░▌     
 ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀       ▀       ▀            ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀       ▀      
```
<!-- Ascii Text: Electronic font from https://www.coolgenerator.com/ascii-text-generator -->

## Description

Paragraph. *(Omit heading and paragraph if one-line summary above is enough.)*

*Repo URL: [https://github.com/mikeo85/outpost](https://github.com/mikeo85/outpost)*

* * * * *

## Installation and Setup

- Prep host system
   - Linux preferred for a server. I tend to run Debian-based distros, but any Linux distro should work fine.
   - Since stuff is Docker-based, can also be run on workstation as `localhost`, including MacOS (partially tested) and Windows (if you have to)
- Install [Docker](https://docs.docker.com/get-docker/) & [Docker Compose](https://docs.docker.com/compose/install/)
- Follow startup instructions on each of the component readme pages linked below.

## Components

### Core Infrastructure & Security

- **[Caddy v2 Reverse Proxy](./caddy/readme.md)**
   - Including Caddy-Security for user authentication & MFA

### Databases

- **[PostgreSQL and pgAdmin](./postgres/readme.md)**

### Apps & Services

- **[Budibase](./budibase/readme.md)** low-code platform

## Metadata

**Created By Mike Owens** | [GitHub](https://github.com/mikeo85) ~ [GitLab](https://gitlab.com/mikeo85) ~ [Twitter](https://twitter.com/quietmike8192)  
(With plenty of help from other online resources and repos that I try to acknowledge wherever possible.)

**License: [MIT](LICENSE)** | *About open source licenses: [ChooseALicense.com](https://choosealicense.com) / [Open Source Initiative](https://opensource.org/licenses) / [Developer's Guide](https://www.toptal.com/open-source/developers-guide-to-open-source-licenses)*

<!-- **Version History:** See [commits](../../commits) or [release history](../../releases). -->

## Acknowledgments

- https://github.com/DoTheEvo/selfhosted-apps-docker
- https://github.com/docker/awesome-compose