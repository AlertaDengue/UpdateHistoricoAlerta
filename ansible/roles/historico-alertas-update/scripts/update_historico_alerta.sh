#!/usr/bin/env bash

# Load environment variables from a .env file
load_env() {
    if [[ -f .env ]]; then
        echo -e "\n >>> Loading environment variables from .env file <<< \n"
        export $(grep -v '^#' .env | xargs)
    fi
}

# Activate the development environment
activate_env() {
    echo -e "\n >>> Activating the dev-alertadengue environment <<< \n"
    source /opt/environments/mambaforge/bin/activate dev-alertadengue || {
        echo "Failed to activate the dev-alertadengue environment" >&2
        exit 1
    }
}

# Refresh materialized views
refresh_materialized_views() {
    echo -e "\n >>> Starting update of MATERIALIZED VIEWS... <<< \n"
    local views=("uf_total_zika_view" "uf_total_chik_view" "uf_total_view" "hist_uf_dengue_materialized_view" \
        "hist_uf_chik_materialized_view" "hist_uf_zika_materialized_view" "\"Municipio\".historico_casos")
    for view in "${views[@]}"; do
        echo "Refreshing $view..."
        PGPASSWORD="$PSQL_PASSWORD" psql -h "$PSQL_HOST" -d "$PSQL_DB" -U "$PSQL_USER" -p "$PSQL_PORT" \
            -c "REFRESH MATERIALIZED VIEW $view;" || {
                echo "Failed to refresh $view" >&2
                exit 1
            }
    done
}

# Clean development environment using makim
clean_develop_env() {
    echo -e "\n >>> Cleaning development environment... <<< \n"
    makim develop.clean || {
        echo "Failed to clean development environment" >&2
        exit 1
    }
}

# Flush memcached
flush_memcached() {
    echo -e "\n >>> Flushing memcached... <<< \n"
    echo 'flush_all' | nc -q1 65.21.204.98 11211 || {
        echo "Failed to flush memcached" >&2
        exit 1
    }
}

# Manage web containers
manage_web_containers() {
    echo -e "\n >>> Managing web containers... <<< \n"
    sugar build --group "$ENV" --services web,worker && \
    sugar kill --group "$ENV" --services web,worker && \
    sugar rm --group "$ENV" --services web,worker --options -f && \
    sugar ext start --group "$ENV" --services web,worker --options -d || {
        echo "Failed to manage web containers" >&2
        exit 1
    }
}

# Update nginx
update_nginx() {
    echo -e "\n >>> Updating nginx... <<< \n"
    cd /opt/services/nginx-infodengue/ && \
    docker-compose --env-file .env --project-name infodengue-prod --file docker/compose-prod.yaml build --no-cache && \
    docker-compose --env-file .env --project-name infodengue-prod --file docker/compose-prod.yaml up -d || {
        echo "Failed to update nginx" >&2
        exit 1
    }
}

# Main script execution
main() {
    set -e  # Exit immediately if a command exits with a non-zero status.
    load_env
    activate_env
    refresh_materialized_views
    clean_develop_env
    flush_memcached
    manage_web_containers
    update_nginx
    echo -e "\n >>> Finished updating AlertaDengue <<< \n"
}

# Execute main
main
