#!/usr/bin/env bash
# Update AlertaDengue stack (DB views, cache, containers, nginx)

set -Eeuo pipefail
trap 'echo "Error on line $LINENO: $BASH_COMMAND" >&2' ERR

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2; exit 1;
  }
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
  echo -e "\n >>> Activating Conda env <<< \n"
  local activate_path="${ACTIVATE_PATH:-/opt/environments/mambaforge/bin/activate}"
  local env_name="${ENV_NAME:-alertadengue}"
  require_cmd conda || true
  # shellcheck disable=SC1090
  source "$activate_path" "$env_name" || {
    echo "Failed to activate '$env_name' at $activate_path" >&2; exit 1;
  }
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
      -h "$PSQL_HOST" -p "$PSQL_PORT" -U "$PSQL_USER" -d "$PSQL_DB" \
      -c "REFRESH MATERIALIZED VIEW ${view};"
  done
}

clean_develop_env() {
  echo -e "\n >>> Cleaning Django cache <<< \n"
  require_cmd makim
  makim develop.clear_cache
}

flush_memcached() {
  echo -e "\n >>> Flushing memcached <<< \n"
  local host="${MEMCACHED_HOST:-65.21.204.98}"
  local port="${MEMCACHED_PORT:-11211}"
  require_cmd nc
  # OpenBSD/GNU nc compatibility: use -w for timeout
  printf "flush_all\r\nquit\r\n" | nc -w 2 "$host" "$port"
}

manage_web_containers() {
  echo -e "\n >>> Managing web containers via containers-sugar <<< \n"
  require_cmd sugar

  # Build images
  sugar compose build \
    --group "${ENV:-dev}" \
    --services web,worker

  # Stop & remove stack (clean)
  sugar compose down \
    --group "${ENV:-dev}" \
    --options "--remove-orphans"

  # Start with extended compose (extra overrides)
  sugar compose-ext up \
    --group "${ENV:-dev}" \
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
  elif command -v docker-compose >/dev/null 2>&1; then
    dc="docker-compose"
  else
    echo "docker compose/docker-compose not found" >&2; exit 1
  fi

  $dc --env-file .env -p "$project_name" -f "$compose_file" build --no-cache
  $dc --env-file .env -p "$project_name" -f "$compose_file" up -d
}

main() {
  echo -e "\n === AlertaDengue update started === \n"
  load_env
  activate_env
  refresh_materialized_views
  clean_develop_env
  flush_memcached
  manage_web_containers
  update_nginx
  echo -e "\n >>> Finished updating AlertaDengue <<< \n"
}

main "$@"
