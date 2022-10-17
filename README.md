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

Stand-alone self-hosting infrastructure with security and a range of apps. Caddy for reverse proxy plus generally heavy use of Docker. Easy and straightforward to add more services as need.

Build yourself an outpost.

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

<!-- ### Databases -->

<!-- - **[PostgreSQL and pgAdmin](./postgres/readme.md)** -->

### Apps & Services

- **[Flame Startpage](./flame/readme.md)** - Easy startpage and bookmarks page
<!-- - **[Budibase](./budibase/readme.md)** - low-code platform -->

## Metadata

**Created By Mike Owens** | [GitHub](https://github.com/mikeo85) ~ [GitLab](https://gitlab.com/mikeo85) ~ [Twitter](https://twitter.com/quietmike8192)  
(With plenty of help from other online resources and repos that I try to acknowledge wherever possible.)

**License: [MIT](LICENSE)**

<!-- **Version History:** See [commits](../../commits) or [release history](../../releases). -->

## Resources and Acknowledgments

- About open source licenses: [ChooseALicense.com](https://choosealicense.com) / [Open Source Initiative](https://opensource.org/licenses) / [Developer's Guide](https://www.toptal.com/open-source/developers-guide-to-open-source-licenses)
- https://github.com/DoTheEvo/selfhosted-apps-docker
- Caddy Security plugin: https://authp.github.io/
- https://github.com/docker/awesome-compose