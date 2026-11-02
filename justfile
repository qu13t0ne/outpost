# outpost - per-service Docker Compose management
#
# Each top-level directory is one service (for example 00_proxy, nextcloud,
# syncthing). A service's configuration lives OUTSIDE this repository, in a resolved
# config directory; the recipes below read it, and `just init` creates it from
# config.example/. That directory is the one place personal state lives.
#
#   just check           hygiene sweep: compose config, hadolint, shellcheck, gitleaks
#   just init            create the config directory from config.example/
#   just up 00_proxy     docker compose up -d --wait
#   just down 00_proxy   docker compose down
#   just pull 00_proxy   docker compose pull
#   just logs 00_proxy   docker compose logs -f --tail=200
#   just ps 00_proxy     docker compose ps
#   just backup 00_proxy print what has to be captured, naming the config directory paths
#   just restore 00_proxy print the matching restore steps
#   just validate        validate the Caddyfile inside the running caddy container
#
# These recipes never create, edit or delete a config file in the repository. The check
# recipe builds a throwaway config tree from config.example/ instead, so no personal value
# is ever read from or written into the repository. See docs/config-model.md.

# --- Config directory resolution ----------------------------------------------
#
# Personal configuration is read from this one place, in this one order, with no fallback
# to the repository. A directory that does not resolve is a failure, not a default, because
# a default is how personal state would return to the tree.
#
#   1. `just config_dir=/path up <service>`  - override for one invocation
#   2. OUTPOST_CONFIG_DIR, when it is set in the environment
#   3. ${XDG_CONFIG_HOME:-$HOME/.config}/outpost

xdg_config_home := env_var_or_default("XDG_CONFIG_HOME", home_directory() + "/.config")
config_dir := env_var_or_default("OUTPOST_CONFIG_DIR", xdg_config_home + "/outpost")

# Exported so docker compose can expand ${OUTPOST_CONFIG_DIR} in the compose files' env_file:
# entries and host-mount paths. There is deliberately no third fallback to the repository.
export OUTPOST_CONFIG_DIR := config_dir

# docker compose, fed the shared per-host env first and the per-service compose.env second.
compose := "docker compose --env-file " + config_dir + "/outpost.env"

# A missing config directory prints the resolution order and the fix, then exits non-zero,
# rather than surfacing as a docker error about a file that happens to be absent.
ensure_config := '''
if [ -d "${OUTPOST_CONFIG_DIR:-}" ]; then
  :
else
  {
    echo "outpost: no config directory found."
    echo "  order tried, first match wins:"
    echo "    1. just config_dir=<path>          this invocation        none"
    echo "    2. OUTPOST_CONFIG_DIR             env                   ${OUTPOST_CONFIG_DIR:-<unset>}"
    echo "    3. \${XDG_CONFIG_HOME:-\$HOME/.config}/outpost        xdg"
    echo
    echo "  fix one of:"
    echo "    just init"
    echo "    just config_dir=/path/to/config up <service>"
    echo "    see docs/config-model.md"
    exit 1
  }
fi
'''

# --- Recipes ------------------------------------------------------------------

# Validate compose files plus Dockerfiles, shell scripts and secrets.
check:
    #!/usr/bin/env bash
    set -uo pipefail
    cd "{{justfile_directory()}}" || exit 1
    fail=0
    tmp=""
    cfg=""
    cleanup() {
      for d in "$tmp" "$cfg"; do
        [ -n "$d" ] && [ -d "$d" ] && rm -rf -- "$d"
      done
    }
    trap cleanup EXIT
    have() { command -v "$1" >/dev/null 2>&1; }

    # x_archive/ and template/ hold non-deployable material (archived services and a
    # scaffold) and are not checked; the deployable services all have a docker-compose.yml
    # and a matching config.example/ directory. The enumeration is the repository's
    # *tracked* compose files, not a find(1) over the disk: a service dir the repository
    # does not ship (immich, a local second dashy instance) is outside the config model, so
    # the check must not read it, let alone FAIL on it. See docs/config-model.md.
    # Fail closed: in a tree with no .git, git ls-files yields nothing and the sweep would
    # silently validate nothing while reporting success.
    if ! tracked_compose=$(git ls-files -- '**/docker-compose.yml' 2>/dev/null); then
      echo "FAIL: git ls-files failed; run just check inside the repository checkout"
      exit 1
    fi
    services() {
      printf '%s\n' "$tracked_compose" | grep -vE '(^|/)(x_archive|template|config.example)/' | sort
    }
    if [ -z "$(services)" ]; then
      echo "FAIL: no tracked compose files found to check"
      exit 1
    fi

    echo "== docker compose config =="
    if ! have docker || ! docker compose version >/dev/null 2>&1; then
      echo "SKIP: docker compose is not available"
    else
      # Build a throwaway config tree from config.example so we never read or write a real
      # config file or .env: env_file: ${OUTPOST_CONFIG_DIR}/... and ${VAR} both resolve
      # against it. The layout is mirrored so `extends: {file: ../compose.common.yml}`
      # resolves, and compose is run from inside the mirror, never the real service dir.
      if [ ! -d config.example ] || [ -z "$(find config.example -type f 2>/dev/null)" ]; then
        echo "FAIL config.example/ is missing or empty"
        fail=1
      else
        if ! tmp=$(mktemp -d "${TMPDIR:-/tmp}/outpost-check.XXXXXX"); then
          echo "FAIL: could not create a temporary directory (set TMPDIR to a writable path)"
          fail=1
        else
          cfg="$tmp/cfg"
          cp -R config.example/. "$cfg"
          mkdir -p "$tmp/root"
          [ -f compose.common.yml ] && cp compose.common.yml "$tmp/root/"
          export OUTPOST_CONFIG_DIR="$cfg"
          while IFS= read -r compose; do
            dir=$(dirname "$compose"); dir=${dir#./}
            mkdir -p "$tmp/root/$dir"
            cp "$dir/docker-compose.yml" "$tmp/root/$dir/"
            [ -f "$dir/docker-compose.override.yml" ] && cp "$dir/docker-compose.override.yml" "$tmp/root/$dir/"
            declare -a envfiles=( --env-file "$cfg/outpost.env" )
            [ -f "$cfg/$dir/compose.env" ] && envfiles+=( --env-file "$cfg/$dir/compose.env" )
            if ( cd "$tmp/root/$dir" && docker compose "${envfiles[@]}" config -q ); then
              printf 'ok   %s\n' "$dir"
            else
              printf 'FAIL %s\n' "$dir"
              fail=1
            fi
          done < <(services)
        fi
      fi
    fi

    echo "== hadolint =="
    if ! have hadolint; then
      echo "SKIP: hadolint is not installed"
    else
      dockerfiles=$(find . -type f -name 'Dockerfile*' -not -path './.git/*' | sort)
      if [ -z "$dockerfiles" ]; then echo "none found"; fi
      for df in $dockerfiles; do
        hadolint "$df" || fail=1
      done
    fi

    echo "== shellcheck =="
    if ! have shellcheck; then
      echo "SKIP: shellcheck is not installed"
    else
      scripts=$(find . -type f -name '*.sh' -not -path './.git/*' | sort)
      if [ -z "$scripts" ]; then echo "none found"; fi
      for sh in $scripts; do
        shellcheck -x "$sh" || fail=1
      done
    fi

    echo "== gitleaks =="
    if ! have gitleaks; then
      echo "SKIP: gitleaks is not installed"
    else
      gitleaks detect --no-git --redact --verbose || fail=1
    fi

    if [ "$fail" -ne 0 ]; then
      echo "check: FAILED"
      exit 1
    fi
    echo "check: ok"

# Create the config directory from config.example/. Refuses to clobber an existing
# non-empty tree, and fails if the example tree is incomplete for a deployable service.
init target="":
    #!/usr/bin/env bash
    set -uo pipefail
    cd "{{justfile_directory()}}" || exit 1

    # Target: the argument, else the resolved config directory - the same value every run
    # recipe reads, so init writes where the recipes will look. just substitutes a shebang
    # recipe's parameters by string interpolation, not as positional $1 (just 1.59).
    target="{{target}}"
    if [ -z "$target" ]; then
      target="$OUTPOST_CONFIG_DIR"
    fi

    # Rule 3: the example tree must cover every deployable service that has a compose file.
    # A silently incomplete tree fails hours later, on a host, as a missing variable. The set
    # is the repository's tracked compose files, so a host's gitignored service dir (immich, a
    # local second dashy instance) is outside the model and cannot abort init. Fail closed:
    # with no .git, git ls-files yields nothing and Rule 3 would verify nothing.
    if ! tracked_compose=$(git ls-files -- '**/docker-compose.yml' 2>/dev/null); then
      echo "init: git ls-files failed; run just init inside the repository checkout" >&2
      exit 1
    fi
    services() {
      printf '%s\n' "$tracked_compose" | grep -vE '(^|/)(x_archive|template|config.example)/' | sort
    }
    if [ -z "$(services)" ]; then
      echo "init: no tracked compose files found; refusing to call config.example/ complete" >&2
      exit 1
    fi
    missing=0
    while IFS= read -r compose; do
      dir=$(dirname "$compose"); dir=${dir#./}
      if [ ! -d "config.example/$dir" ]; then
        echo "init: config.example/ is missing $dir/ (repo has $dir/docker-compose.yml but no example)" >&2
        missing=1
      fi
    done < <(services)
    if [ "$missing" -ne 0 ]; then
      echo "init: aborting: the example tree is incomplete" >&2
      exit 1
    fi

    # Rule 1: never merge or overwrite. Refuse a non-empty target.
    if [ -d "$target" ] && [ -n "$(ls -A "$target" 2>/dev/null)" ]; then
      echo "init: $target already exists and is not empty; refusing to overwrite" >&2
      exit 1
    fi

    # Rule 2: create the tree and report every file written and the final path. A failed
    # mkdir or cp exits non-zero rather than reporting a success that did not happen.
    if ! mkdir -p "$target"; then
      echo "init: could not create $target" >&2
      exit 1
    fi
    if ! cp -R config.example/. "$target"; then
      echo "init: failed to copy config.example/ into $target" >&2
      exit 1
    fi
    n=0
    while IFS= read -r f; do
      echo "  ${f#config.example/}"
      n=$((n + 1))
    done < <(find config.example -type f | sort)
    echo "init: wrote $n file(s) under $target"

# Start the service in the given directory in the background and wait for health.
up dir:
    #!/usr/bin/env bash
    set -uo pipefail
    cd "{{dir}}" || exit 1
    {{ensure_config}}
    {{compose}} --env-file "{{config_dir}}/{{dir}}/compose.env" up -d --wait

# Stop and remove the containers of the given directory.
down dir:
    #!/usr/bin/env bash
    set -uo pipefail
    cd "{{dir}}" || exit 1
    {{ensure_config}}
    {{compose}} --env-file "{{config_dir}}/{{dir}}/compose.env" down

# Pull the images used by the given directory.
pull dir:
    #!/usr/bin/env bash
    set -uo pipefail
    cd "{{dir}}" || exit 1
    {{ensure_config}}
    {{compose}} --env-file "{{config_dir}}/{{dir}}/compose.env" pull

# Follow the logs of the given directory.
logs dir:
    #!/usr/bin/env bash
    set -uo pipefail
    cd "{{dir}}" || exit 1
    {{ensure_config}}
    {{compose}} --env-file "{{config_dir}}/{{dir}}/compose.env" logs -f --tail=200

# Show container status for the given directory.
ps dir:
    #!/usr/bin/env bash
    set -uo pipefail
    cd "{{dir}}" || exit 1
    {{ensure_config}}
    {{compose}} --env-file "{{config_dir}}/{{dir}}/compose.env" ps

# Print the backup checklist for the given directory. Copies nothing; it names the
# configuration directory paths that now hold the state instead of the old per-service .env.
backup dir:
    #!/usr/bin/env bash
    set -uo pipefail
    cd "{{dir}}" || exit 1
    echo "Backup checklist for {{dir}} - this recipe only prints, it copies nothing."
    echo
    echo "Capture all of the following:"
    echo "  1. Compose files     : docker-compose.yml, plus docker-compose.override.yml if present"
    echo "  2. Configuration dir : the resolved config directory, which the recipes read from:"
    echo "       ${OUTPOST_CONFIG_DIR}/outpost.env              (shared per-host facts: every service)"
    if [ -f "${OUTPOST_CONFIG_DIR}/{{dir}}/compose.env" ]; then
      echo "       ${OUTPOST_CONFIG_DIR}/{{dir}}/compose.env          (this service's interpolation values)"
    fi
    if [ -f "${OUTPOST_CONFIG_DIR}/{{dir}}/app.env" ]; then
      echo "       ${OUTPOST_CONFIG_DIR}/{{dir}}/app.env              (this service's app config and secrets)"
    fi
    echo "  3. Service config    : any file this service reads from the config dir (the Caddyfile, the syncthing conf)"
    echo "  4. Host data paths   : every host path mounted by the compose file(s), listed below"
    echo "  5. Data roots        : the APPDATA / CONFIG_PATH / DATADIR values in the files above"
    echo "  6. Named volumes     : any volume declared in the compose file (docker volume ls)"
    echo
    compose_files=$(ls docker-compose*.yml 2>/dev/null)
    if [ -z "$compose_files" ]; then
      echo "WARNING: no docker-compose*.yml found in this directory"
    else
      echo "Host paths referenced by the compose files:"
      grep -hoE '^[[:space:]]+-[[:space:]]+[^:]+:[^:]+' $compose_files 2>/dev/null \
        | sed -E 's/^[[:space:]]+-[[:space:]]+//; s/:[^:]*$//' \
        | grep -E '^(\.|/|\$)' | sort -u | sed 's/^/    /'
    fi
    echo
    cfgdir="${OUTPOST_CONFIG_DIR}/{{dir}}"
    roots="$([ -f "$cfgdir/compose.env" ] && echo "compose.env"); "
    roots="$roots$([ -f "$cfgdir/app.env" ] && echo "app.env"); "
    roots="$(echo $roots | sed 's/; //g; s/ $//')"
    echo "Data roots and data values declared in $cfgdir${roots:+ / $roots}${roots:+}:"
    grep -hE '^(APPDATA|CONFIG_PATH|DATADIR|UPLOAD_LOCATION|DB_DATA_LOCATION|DATA_DIR)=' \
      "${cfgdir}/compose.env" "${cfgdir}/app.env" "${OUTPOST_CONFIG_DIR}/outpost.env" 2>/dev/null \
      | sed 's/^/    /' || echo "    (none declared)"

# Print the restore checklist for the given directory. Changes nothing.
restore dir:
    #!/usr/bin/env bash
    set -uo pipefail
    cd "{{dir}}" || exit 1
    cfgdir="${OUTPOST_CONFIG_DIR}/{{dir}}"
    echo "Restore checklist for {{dir}} - this recipe only prints, it changes nothing."
    echo
    echo "  1. Restore the compose files for this directory from the repository."
    echo "  2. Restore the config directory from its versioned repo. Never recreate it from"
    echo "     config.example/: the examples hold placeholders only, and secrets cannot be"
    echo "     regenerated. Restore:"
    echo "       $cfgdir"
    echo "       ${OUTPOST_CONFIG_DIR}/outpost.env    (shared per-host facts)"
    echo "  3. Restore every host data path and named volume listed by 'just backup {{dir}}'."
    echo "  4. Restore any service config the service reads from the config dir"
    echo "     (the Caddyfile, the syncthing conf)."
    echo "  5. Check ownership and permissions on the restored paths against the container's"
    echo "     PUID/PGID or UID/GID before starting anything."
    echo "  6. Start the service with 'just up {{dir}}' and confirm 'just ps {{dir}}' is healthy."
    echo "  7. Restored apps gated by the identity provider need their client secrets re-checked"
    echo "     after a restore, because redirect URLs must match the live hostname."

# Validate the Caddyfile inside the running caddy container.
validate:
    #!/usr/bin/env bash
    set -uo pipefail
    if ! command -v docker >/dev/null 2>&1; then
      echo "validate: docker is not available here. Run this on the proxy host."
      exit 1
    fi
    if ! docker ps --filter 'name=^caddy$' --filter 'status=running' --quiet | grep -q .; then
      echo "validate: container 'caddy' is not running."
      echo "  Start it with: just up 00_proxy"
      echo "  The expected check once it runs is:"
      echo "    docker exec caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile"
      exit 1
    fi
    docker exec caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
