#!/usr/bin/env bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <file> <year> <cid>"
    exit 1
fi

FILE=$1
YEAR=$2
CID=$3

activate_env() {
    echo -e "\n >>> Activating the alertadengue environment <<< \n"
    # source /opt/environments/mambaforge/bin/activate alertadengue || {
    source /opt/environments/mambaforge/bin/activate dev-alertadengue || {
        echo "Failed to activate the alertadengue environment" >&2
        exit 1
    }
}

run_upload_sinan() {
    echo -e "\n >>> Executing load_sinan command on AlertaDengue <<< \n"
    cd /opt/services/AlertaDengue
    # cd /opt/services/staging_AlertaDengue
    sugar exec --service web --cmd python manage.py load_sinan $FILE $YEAR --default-cid $CID || {
        echo "Failed to execute load_sinan" >&2
        exit 1
    }
}

main() {
  set -e
  activate_env
  run_upload_sinan
}

main
