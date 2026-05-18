# MlflowAuth

Минимальная Docker-сборка MLflow Server с Basic Auth, PostgreSQL backend-store и S3-хранилищем артефактов.

## Состав проекта

- `Dockerfile` — образ Python 3.11 с `mlflow[auth]`, `boto3`, `psycopg2-binary`.
- `start.sh` — генерация `basic_auth.ini` и запуск `mlflow server` с `--app-name basic-auth`.
- `docker-compose.mlflow.yml` — контейнер `mlflow`, проброс порта `5000`, переменные окружения для PostgreSQL и S3.
- `.env.mlflow` — параметры подключения к PostgreSQL/S3 (создать по шаблону `.env.mlflow.example`).

## Быстрый старт

1. Подготовьте файл окружения:

   ```bash
   cp .env.mlflow.example .env.mlflow
   ```

2. Запустите сервис:

   ```bash
   docker compose -f docker-compose.mlflow.yml --env-file .env.mlflow up -d --build
   ```

3. Проверьте доступность:

   - URL: `http://localhost:5000`
   - Авторизация: значения `MLFLOW_AUTH_ADMIN_USERNAME` и `MLFLOW_AUTH_ADMIN_PASSWORD`.
