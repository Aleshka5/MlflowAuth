#!/bin/sh
set -eu

cat > /tmp/basic_auth.ini <<EOF
[mlflow]
default_permission = READ
database_uri = ${MLFLOW_AUTH_DB_URI}
admin_username = ${MLFLOW_AUTH_ADMIN_USERNAME}
admin_password = ${MLFLOW_AUTH_ADMIN_PASSWORD}
EOF

export MLFLOW_AUTH_CONFIG_PATH=/tmp/basic_auth.ini

exec mlflow server \
  --app-name basic-auth \
  --host 0.0.0.0 \
  --allowed-hosts "*" \
  --cors-allowed-origins "*" \
  --port 5000 \
  --backend-store-uri "${MLFLOW_BACKEND_STORE_URI}" \
  --artifacts-destination "${MLFLOW_ARTIFACTS_DESTINATION}" \
  --serve-artifacts
