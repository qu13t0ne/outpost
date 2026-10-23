# outpost - per-service Docker Compose management
#
# Each top-level directory is one service (for example 00_proxy, nextcloud,
# syncthing). Recipes that take a service directory run inside that directory,
# so that directory's own docker-compose.yml, docker-compose.override.yml and
# .env are the only inputs. There is no shared or global state.
#
#   just check              hygiene sweep: compose config, hadolint, shellcheck, gitleaks
#   just up 00_proxy        docker compose up -d --wait
#   just down 00_proxy      docker compose down
#   just pull 00_proxy      docker compose pull
#   just logs 00_proxy      docker compose logs -f --tail=200
#   just ps 00_proxy        docker compose ps
#   just backup 00_proxy    print what has to be captured for that directory
#   just restore 00_proxy   print the matching restore steps
#   just validate           validate the Caddyfile inside the running caddy container
#
# These recipes never create, edit or delete a .env file in the repository.
# The check recipe copies an env template into a throwaway temp directory
# instead. Env templates are expected at .env.example; the legacy names
# template_env and template-env are still accepted until the rename lands.

# Validate compose files plus Dockerfiles, shell scripts and secrets in the repo.
check:
    #!/usr/bin/env bash
    set -uo pipefail
    cd "{{justfile_directory()}}" || exit 1
    fail=0
    tmp=""

    cleanup() {
      if [ -n "$tmp" ] && [ -d "$tmp" ]; then rm -rf -- "$tmp"; fi
    }
    trap cleanup EXIT

    have() { command -v "$1" >/dev/null 2>&1; }

    echo "== docker compose config =="
    if ! have docker || ! docker compose version >/dev/null 2>&1; then
      echo "SKIP: docker compose is not available"
    else
      # The temp tree mirrors the repository layout, so relative references such as
      # `extends: {file: ../compose.common.yml}` still resolve. Compose is run from inside
      # the mirrored service directory, never in the real one, so no .env is ever created
      # in the repository.
      while IFS= read -r compose; do
        dir=$(dirname "$compose")
        dir=${dir#./}
        tmp=$(mktemp -d)
        mkdir -p "$tmp/root/$dir"
        if [ -f compose.common.yml ]; then
          cp compose.common.yml "$tmp/root/"
        fi
        cp "$dir/docker-compose.yml" "$tmp/root/$dir/"
        if [ -f "$dir/docker-compose.override.yml" ]; then
          cp "$dir/docker-compose.override.yml" "$tmp/root/$dir/"
        fi
        envlabel="none"
        if [ -f "$dir/.env" ]; then
          cp "$dir/.env" "$tmp/root/$dir/.env"
          envlabel=".env"
        else
          for candidate in .env.example template_env template-env; do
            if [ -f "$dir/$candidate" ]; then
              cp "$dir/$candidate" "$tmp/root/$dir/.env"
              envlabel="$candidate"
              break
            fi
          done
        fi
        if ( cd "$tmp/root/$dir" && docker compose config -q ); then
          echo "ok   $dir (env: $envlabel)"
        else
          echo "FAIL $dir (env: $envlabel)"
          fail=1
        fi
        rm -rf -- "$tmp"
        tmp=""
      done < <(find . -name docker-compose.yml -not -path './.git/*' | sort)
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

# Start the service in the given directory in the background and wait for health.
up dir:
    @cd {{dir}} && docker compose up -d --wait

# Stop and remove the containers of the given directory.
down dir:
    @cd {{dir}} && docker compose down

# Pull the images used by the given directory.
pull dir:
    @cd {{dir}} && docker compose pull

# Follow the logs of the given directory.
logs dir:
    @cd {{dir}} && docker compose logs -f --tail=200

# Show container status for the given directory.
ps dir:
    @cd {{dir}} && docker compose ps

# Print the backup checklist for the given directory. Copies nothing.
backup dir:
    #!/usr/bin/env bash
    set -uo pipefail
    cd "{{dir}}" || exit 1
    echo "Backup checklist for {{dir}} - this recipe only prints, it copies nothing."
    echo
    echo "Capture all of the following:"
    echo "  1. Compose files   : docker-compose.yml, plus docker-compose.override.yml if present"
    echo "  2. Environment     : .env - it is gitignored and holds the real secrets"
    echo "  3. Host data paths : every host path mounted by the compose file(s), listed below"
    echo "  4. Data roots      : APPDATA / CONFIG_PATH / DATADIR style values from the env file"
    echo "  5. Named volumes   : any volume declared in the compose file (docker volume ls)"
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
    envfile=""
    for candidate in .env .env.example template_env template-env; do
      if [ -f "$candidate" ]; then envfile="$candidate"; break; fi
    done
    if [ -z "$envfile" ]; then
      echo "WARNING: no env file found in this directory"
    else
      echo "Data roots declared in $envfile:"
      grep -E '^(APPDATA|CONFIG_PATH|DATADIR|UPLOAD_LOCATION|DB_DATA_LOCATION|DATA_DIR)=' "$envfile" \
        | sed 's/^/    /' || echo "    (none declared)"
    fi

# Print the restore checklist for the given directory. Changes nothing.
restore dir:
    #!/usr/bin/env bash
    set -uo pipefail
    cd "{{dir}}" || exit 1
    echo "Restore checklist for {{dir}} - this recipe only prints, it changes nothing."
    echo
    echo "  1. Restore the compose files for this directory."
    echo "  2. Restore .env from the backup. Never recreate it from the template: the template"
    echo "     holds placeholders only, and secrets cannot be regenerated."
    echo "  3. Restore every host data path and named volume listed by 'just backup {{dir}}'."
    echo "  4. Check ownership and permissions on the restored paths against the container's"
    echo "     PUID/PGID or UID/GID before starting anything."
    echo "  5. Start the service with 'just up {{dir}}' and confirm 'just ps {{dir}}' is healthy."
    echo "  6. Restored apps that were gated by the identity provider need their client secrets"
    echo "     re-checked after a restore, because redirect URLs must match the live hostname."

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
