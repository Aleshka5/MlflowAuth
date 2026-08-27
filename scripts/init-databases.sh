#!/bin/bash
set -euo pipefail

# Official image already creates POSTGRES_DB on first start.
# This script additionally creates POSTGRES_AUTH_DB (and is a no-op if both exist).

create_database() {
  local database="$1"
  local exists

  exists="$(psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" \
    -tAc "SELECT 1 FROM pg_database WHERE datname='${database}'")"

  if [ "${exists}" = "1" ]; then
    echo "Database '${database}' already exists"
    return 0
  fi

  echo "Creating database '${database}'"
  psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" \
    -c "CREATE DATABASE \"${database}\";"
}

create_database "${POSTGRES_DB}"
create_database "${POSTGRES_AUTH_DB}"
