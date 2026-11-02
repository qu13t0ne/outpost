# Configuration Model

Personal configuration is read from a directory *outside* the OUTPOST tree, resolved in one place.
The tree ships a mirrored example and refuses to hold personal state. This document is the source of
record for how configuration is found, shaped, versioned, and migrated.

**Why it exists.** The repository is public. Personal state inside the working tree is one `git add -A`
from being published and one lost disk from being gone. The goal is not a tool that refuses personal
values; it is a tree with nowhere to put them, so the failure cannot happen by habit. This is decision
X-14 and delta DL-22. This document describes what the repository actually does after T-031.

## Resolution order

Personal configuration is resolved in exactly one place, in the `justfile`, first match wins:

1. `just config_dir=/path up <service>` - an override for one invocation.
2. `OUTPOST_CONFIG_DIR`, when set in the environment.
3. `${XDG_CONFIG_HOME:-$HOME/.config}/outpost` - the default.

There is deliberately **no fourth fallback to the repository**. A config directory that does not resolve
is a failure, not a default, because a default is how personal state returns to the tree.

The three paths, and the missing-directory case, verify as:

```
just --evaluate config_dir                       # the default, $HOME/.config/outpost
OUTPOST_CONFIG_DIR=/tmp/x just --evaluate config_dir   # the env wins
just config_dir=/tmp/x --evaluate config_dir         # the override wins
```

Every recipe that reads configuration goes through the exported `OUTPOST_CONFIG_DIR` and the
`compose` variable, which feeds docker compose the shared file first and the service's file second:

```
export OUTPOST_CONFIG_DIR := config_dir
compose := "docker compose --env-file " + config_dir + "/outpost.env"
```

So a run recipe is:

```
up dir:
    cd {{dir}} && {{compose}} --env-file {{config_dir}}/{{dir}}/compose.env up -d --wait
```

`down`, `pull`, `logs`, and `ps` use the same two files. `backup` and `restore` do not run a stack;
they print the config-directory paths that now hold the state.

## The tree

`config.example/` mirrors the real tree one file per file, and `$OUTPOST_CONFIG_DIR/` is a copy of it
that holds the real values:

```
$OUTPOST_CONFIG_DIR/
  outpost.env              shared, per-host facts
  00_proxy/
    compose.env            values docker compose interpolates
    app.env                values handed to the container
    Caddyfile
  01_authentik/
    compose.env
    app.env
  cyberchef/
    compose.env
  dashy/
    compose.env
  nextcloud/
    compose.env
  speedtest-tracker/
    compose.env
    app.env
  syncthing/
    compose.env
  wallabag/
    compose.env
```

`just init` copies `config.example/` to the resolved directory. It refuses a non-empty target, reports
every file it wrote, and fails if `config.example/` is missing a service that has a compose file.

### Two env files per service, and why

The split is the point. A service that reads any config via `env_file:` has both files; a service that
only interpolates has `compose.env` alone.

- **`compose.env`** is read by `docker compose` *before* it parses the YAML, so it can hold only the
  values the YAML interpolates with `${VAR}`: addresses, ports, `APPDATA`, and host paths. A value that
  lives only in an `env_file` is not available for interpolation, so secrets that the YAML expands
  (`${PG_PASS:?}`, `${AUTHENTIK_SECRET_KEY:?}`) must live here.
- **`app.env`** is handed to the container through `env_file:`, so it holds the application's own settings
  and the secrets the container's process needs.

One file doing both jobs works until the first value that must be a path on the host and a different path
in the container, or a secret the YAML must interpolate; then it is unfixable, which is why the split is
structural.

## What is per-host

`outpost.env` holds the three values that **every** service's compose file interpolates, written once:

- `BIND_ADDR` - this host's single LAN address. Never `0.0.0.0`: binding every service to every
  interface reopens the ingress the per-host nftables rulesets exist to close.
- `TAILSCALE_ADDR` - this host's tailnet address.
- `APPDATA` - this host's data root.

Because the `compose` variable feeds `outpost.env` first, a service whose file interpolates nothing of its
own leaves `compose.env` empty and inherits its addresses from `outpost.env`. This is the rule that
stops the same address being written once per service and rotting in N places.

Per-service facts live in that service's own `compose.env` / `app.env`. By "one value, one place", a
fact that one service consumes lives where that service reads it: `DOMAIN` and `EMAIL_FOR_ACME` are
Caddy facts, so they sit in `00_proxy/app.env` (where caddy reads them through `env_file:` and the
Caddyfile expands `{$DOMAIN}`, `{$EMAIL_FOR_ACME}`), not in `outpost.env`. `outpost.env` keeps only the
three addresses-and-root facts that are literally shared by interpolation.

## Keeping your config private

`.gitignore` is default-deny for the shapes a config file takes, anywhere in the tree, with one
allowlist for the examples:

```
# config shapes: denied anywhere
**/.env
**/.env.*
**/*.local.*
**/compose.env
**/app.env
**/outpost.env
**/Caddyfile
**/docker-compose.override.yml
**/conf/
**/appdata/
**/APPDATA/
**/user-data/
**/*.custom
**/*.pem
**/*.key
**/*.p12
**/*.bak
**/*.bak.*

# allowlist, and only it
!**/.env.example
!config.example/**
```

The allowlist is **last**, because gitignore is first-match-wins and a negation only wins when it comes
after the ignore it answers. It is not a blanket `*` with a long allowlist: a blanket deny makes a newly
added documentation file invisible to `git status`, and silent omission is a worse failure than a noisy
one. A personal config shaped like `compose.env` or `.env` has no path into the tree, so a `git add -A`
cannot carry it out.

The versions of this configuration are not in this repository. They live in a private companion repository
reachable on the overlay only, inside the estate, never on the internet or a hosted forge (X-15, X-17).
The two env files the recipe reads are read from `$OUTPOST_CONFIG_DIR/`, which is not the working tree.

### The private companion repository

Per X-14 and design V-5, the config tree is versioned by a small private forge (Forgejo, decided X-15)
inside the estate. Its shape:

```
<config-repo>/
  outpost.env
  00_proxy/ {compose.env, app.env, Caddyfile}
  01_authentik/ {compose.env, app.env}
  ...
  PIN                       a file naming the OUTPOST commit this config was built against
```

The `PIN` is the recommended link to OUTPOST, the W-8 deploy-ref model already in use: one line naming
the OUTPOST commit the tree was generated from, so a clone of the config repo plus `git init` (or a
checkout of the pinned OUTPOST commit) reproduces the estate. A submodule was rejected: it adds a second
has-a relationship and a second way to be at the wrong commit, for no benefit over a one-line pin.

## Migration, `.env` to `$OUTPOST_CONFIG_DIR/<service>/app.env`

For an operator who already runs this, T-032 rewrites the host's config from the old per-service `.env`
to the new tree. The rule is mechanical and changes no address or service:

1. `just init` writes `$OUTPOST_CONFIG_DIR/` from `config.example/`.
2. For each service, move `<service>/.env` to `$OUTPOST_CONFIG_DIR/<service>/app.env`, and create
   `compose.env` with the interpolation values that were mixed in (`BIND_ADDR`, `PORT`, `APPDATA` at the
   service level).
3. Move `syncthing/conf/` to the config tree (see the note below).
4. Pull the refactored compose files, run `just check`, then `just up` one service at a time, in the
   order the runbook already uses.

`00_proxy/static/` is the one mount that does **not** move: it is the error page set the repository ships
as an artifact (see "Notes and exceptions").

## Notes and exceptions

- **`syncthing/conf/`.** The compose file mounts `${OUTPOST_CONFIG_DIR}/syncthing/conf`, but the
  directory is not shipped in `config.example/`: an empty directory cannot be tracked under a directory
  git excludes (`**/conf/`), and Docker creates the mount point on first start. The first `just up
  syncthing` creates it; after that it holds the device identity and is the config that `just backup
  syncthing` names.
- **`dashy/user-data/`.** Same class as `syncthing/conf/`, and it fails the same silent way: the compose
  file mounts `${OUTPOST_CONFIG_DIR}/dashy/user-data`, the tree does not ship the directory, Docker
  creates it empty on first start, and a recreate that finds it empty starts dashy with no config. The
  first `just up dashy` creates it; `just backup dashy` names it.
- **A service the repository does not track is outside this model.** Two live examples: the vendor
  `immich` compose, gitignored because every upgrade replaces it, and a local `dashy_admin.custom`
  second instance, gitignored by the `**/*.custom` rule. Such a directory is not enumerated by
  `just init` or `just check` - both read the repository's tracked set, not the disk - so its presence
  cannot abort `init` or paint a `FAIL` in `check`, and the model makes no claim about its contents. Its
  ports are bound literally, by section 3 of `03-binds-102.md`. That is the design: the model covers what
  the repository ships, and a service it does not ship carries its own configuration.
- **`00_proxy/Caddyfile`.** The example ships once, at `config.example/00_proxy/Caddyfile` (moved from
  `00_proxy/Caddyfile.example` by git rename, so history is preserved). The old per-directory
  `Caddyfile.example` and its `!**/Caddyfile.example` ignore rule are gone: two copies of the same
  example is exactly the rot this design exists to prevent.
- **`00_proxy/static/` is a repository artifact.** It is the error page set the proxy ships with, not
  personal config, so it stays repo-relative under `00_proxy/static/`. Only the Caddyfile moves to the
  config tree.
- **`x_archive/` and `template/` are out of the check and init scans.** They hold archived services and
  a scaffold, neither deployable. `just check` and `just init` skip them by name; every deployable
  service has a `docker-compose.yml` and a matching `config.example/<service>/` directory, which `just
  init` verifies.
- **`compose.common.yml` stays at the repository root.** It is tool configuration, not personal
  configuration.
- **immich** is not in the tree: its `docker-compose.yml` is the vendor's file, gitignored on purpose and
  replaced on every upgrade. immich reads its own `.env`, which the operator fills per the Immich
  documentation; that operator's `BIND_ADDR` binding is a per-step choice in immich's readme, not a value
  the config model carries.
