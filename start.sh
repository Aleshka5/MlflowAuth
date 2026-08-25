#!/bin/sh
set -eu

host="${POSTGRES_HOST:-}"
host="${host#http://}"
host="${host#https://}"
host="${host%%/*}"

if [ "$host" = "localhost" ] || [ "$host" = "127.0.0.1" ]; then
  host="host.docker.internal"
fi

port="${POSTGRES_PORT:-5432}"

if [ -z "${POSTGRES_USER:-}" ] || [ -z "$host" ] || [ -z "${POSTGRES_DB:-}" ]; then
  echo "Missing PostgreSQL settings. Use --env-file .env.mlflow or env_file in compose." >&2
  echo "Required: POSTGRES_USER, POSTGRES_HOST, POSTGRES_DB" >&2
  exit 1
fi

export MLFLOW_BACKEND_STORE_URI="postgresql+psycopg2://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${host}:${port}/${POSTGRES_DB}"
export MLFLOW_ARTIFACTS_DESTINATION="s3://${MLFLOW_BUCKET_NAME}"

exec mlflow server \
  --host 0.0.0.0 \
  --allowed-hosts "*" \
  --cors-allowed-origins "*" \
  --port 5000 \
  --backend-store-uri "${MLFLOW_BACKEND_STORE_URI}" \
  --artifacts-destination "${MLFLOW_ARTIFACTS_DESTINATION}" \
  --serve-artifacts
