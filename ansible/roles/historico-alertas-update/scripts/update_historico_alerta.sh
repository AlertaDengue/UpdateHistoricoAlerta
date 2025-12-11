#!/usr/bin/env bash
# Update AlertaDengue stack (DB views, cache, containers, nginx)

set -Eeuo pipefail
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >&2' ERR

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

load_env() {
  if [[ -f .env ]]; then
    echo -e "\n >>> Loading environment from .env <<< \n"
    set -a
    # shellcheck disable=SC1091
    . ./.env
    set +a
  fi
}

activate_env() {
  echo -e "\n >>> Activating Conda env (if available) <<< \n"

  local env_name="${ENV_NAME:-alertadengue}"
  local conda_sh="${CONDA_SH:-/opt/environments/mambaforge/etc/profile.d/conda.sh}"

  # Already inside the desired env
  if [[ "${CONDA_DEFAULT_ENV:-}" == "$env_name" ]]; then
    echo "Conda environment '$env_name' already active."
    return 0
  fi

  # Try to source conda initialization script
  if [[ ! -f "$conda_sh" ]]; then
    echo "Conda init script '$conda_sh' not found; continuing without conda."
    return 0
  fi

  # shellcheck disable=SC1090
  . "$conda_sh"

  if ! has_cmd conda; then
    echo "conda command not available after sourcing; continuing without conda."
    return 0
  fi

  # Activate env if it exists
  if conda env list | awk '{print $1}' | grep -qx "$env_name"; then
    if ! conda activate "$env_name"; then
      echo "Failed to activate conda env '$env_name'; continuing with base."
    fi
  else
    echo "Conda env '$env_name' not found; continuing with base env."
  fi
}

refresh_materialized_views() {
  echo -e "\n >>> Refreshing MATERIALIZED VIEWS <<< \n"

  : "${PSQL_HOST:?PSQL_HOST is required}"
  : "${PSQL_PORT:?PSQL_PORT is required}"
  : "${PSQL_DB:?PSQL_DB is required}"
  : "${PSQL_USER:?PSQL_USER is required}"
  : "${PSQL_PASSWORD:?PSQL_PASSWORD is required}"

  local -a views=(
    "uf_total_zika_view"
    "uf_total_chik_view"
    "uf_total_view"
    "hist_uf_dengue_materialized_view"
    "hist_uf_chik_materialized_view"
    "hist_uf_zika_materialized_view"
    "city_count_by_uf_dengue_materialized_view"
    "city_count_by_uf_chikungunya_materialized_view"
    "city_count_by_uf_zika_materialized_view"
    "epiyear_summary_materialized_view"
    "\"Municipio\".historico_casos"
  )

  for view in "${views[@]}"; do
    echo "Refreshing ${view}..."
    PGPASSWORD="$PSQL_PASSWORD" psql \
      -h "$PSQL_HOST" -p "$PSQL_PORT" \
      -U "$PSQL_USER" -d "$PSQL_DB" \
      -c "REFRESH MATERIALIZED VIEW ${view};"
  done
}

flush_memcached() {
  echo -e "\n >>> Flushing memcached (via containers-sugar) <<< \n"

  local group="${ENV:-prod}"
  local service="${MEMCACHED_SERVICE:-memcached}"
  local cmd="sh -lc 'printf \"flush_all\r\nquit\r\n\" | nc -w 2 127.0.0.1 11211'"

  # Non-interactive (Ansible / nohup): no TTY
  if [[ ! -t 0 && ! -t 1 ]]; then
    echo "No TTY detected; attempting direct memcached flush on host:11211..."

    if has_cmd nc; then
      if printf "flush_all\r\nquit\r\n" | nc -w 2 127.0.0.1 11211 2>/dev/null
      then
        echo "Memcached flush via host:11211 succeeded."
      else
        echo "Could not reach memcached on host:11211; skipping flush."
      fi
    else
      echo "nc command not found; skipping memcached flush."
    fi

    # Do not fail the script in non-interactive mode
    return 0
  fi

  # Interactive path: use containers-sugar if available
  if ! has_cmd sugar; then
    echo "sugar command not found; skipping memcached flush."
    return 0
  fi

  if ! sugar compose exec \
        --group "$group" \
        --service "$service" \
        --cmd "$cmd"
  then
    echo "sugar compose exec for memcached failed; trying direct host flush..."

    if has_cmd nc; then
      printf "flush_all\r\nquit\r\n" | nc -w 2 127.0.0.1 11211 2>/dev/null || true
    fi
  fi
}

manage_web_containers() {
  echo -e "\n >>> Managing web containers via containers-sugar <<< \n"

  if ! has_cmd sugar; then
    echo "sugar command not found; skipping web container management."
    return 0
  fi

  local group="${ENV:-dev}"

  sugar compose build \
    --group "$group" \
    --services web,worker

  sugar compose down \
    --group "$group" \
    --options "--remove-orphans"

  sugar compose-ext up \
    --group "$group" \
    --services web,worker \
    --options "-d"
}

update_nginx() {
  echo -e "\n >>> Updating nginx <<< \n"

  local proj_dir="/opt/services/nginx-infodengue"
  local compose_file="docker/compose-prod.yaml"
  local project_name="infodengue-prod"

  cd "$proj_dir"

  local dc
  if docker compose version >/dev/null 2>&1; then
    dc="docker compose"
  elif has_cmd docker-compose; then
    dc="docker-compose"
  else
    echo "docker compose/docker-compose not found" >&2
    exit 1
  fi

  $dc --env-file .env -p "$project_name" -f "$compose_file" build --no-cache
  $dc --env-file .env -p "$project_name" -f "$compose_file" up -d
}

main() {
  echo -e "\n === AlertaDengue update started === \n"

  load_env
  activate_env
  refresh_materialized_views
  flush_memcached
  manage_web_containers
  update_nginx

  echo -e "\n >>> Finished updating AlertaDengue <<< \n"
}

main "$@"
