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

# Remove the PostgreSQL staging data directory
remove_pg_staging_data() {
  echo -e "\n >>> Removing PostgreSQL staging data directory <<< \n"
  rm -rf /Storage/staging_data/pg_data_dengue_staging || {
    echo "Failed to remove PostgreSQL staging data directory" >&2
    exit 1
  }
}

# Copy PostgreSQL data from production to staging
copy_prod_to_staging() {
  echo -e "\n >>> Copying PostgreSQL data from production to staging <<< \n"
  cp -rp /Storage/infodengue_data/pg_data_dengue_prod /Storage/staging_data/pg_data_dengue_staging || {
    echo "Failed to copy data from production to staging" >&2
    exit 1
  }
}

# Update staging AlertaDengue
update_staging_alertadengue() {
  echo -e "\n >>> Updating Staging AlertaDengue <<< \n"
  
  # Operations on web and database containers
  echo -e "\n >>> Performing operations on web containers <<< \n"
  sugar build --group "$ENV" --services stagindb,web,worker || { echo "Build failed" >&2; exit 1; }
  sugar kill --group "$ENV" --services stagingdb,web,worker || { echo "Kill failed" >&2; exit 1; }
  sugar rm --group "$ENV" --services stagingdb,web,worker --options -f || { echo "Remove failed" >&2; exit 1; }
  sugar ext start --group "$ENV" --services stagingdb,web,worker --options -d || { echo "Start failed" >&2; exit 1; }
}

# Main script execution
main() {
  set -e  # Exit immediately if a command exits with a non-zero status.
  load_env
  activate_env
  remove_pg_staging_data
  copy_prod_to_staging
  update_staging_alertadengue
}

# Execute main
main
