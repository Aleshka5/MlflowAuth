# MlflowAuth

Минимальная Podman-сборка MLflow Server без аутентификации, с PostgreSQL backend-store и MinIO (S3) для артефактов.

## Состав проекта

- `Dockerfile.mlflow` — образ Python 3.11 с `mlflow`, `boto3`, `psycopg2-binary`.
- `start.sh` — сборка URI PostgreSQL и запуск `mlflow server`.
- `docker/docker-compose-standalone.yml` — только `mlflow`, внешние сети `dbs` (Postgres) и `s3` (MinIO).
- `docker/docker-compose-full.yml` — полный стек: `mlflow`, `postgres`, `minio` и одноразовый `minio-init`.
- `docker/postgres/init-databases.sh` — создание базы `POSTGRES_DB` при первом старте Postgres (полный стек).
- `docker/minio/init-bucket.sh` — создание bucket `MLFLOW_BUCKET_NAME` после старта MinIO (полный стек).
- `.env.mlflow` — параметры подключения к PostgreSQL/S3 (создать по шаблону `.env.mlflow.example`). `POSTGRES_HOST` — hostname без `http://`.

## Быстрый старт

1. Подготовьте файл окружения:

   ```bash
   cp .env.mlflow.example .env.mlflow
   ```

   Подставьте свои значения вместо плейсхолдеров. Для standalone `POSTGRES_HOST` и `MLFLOW_S3_ENDPOINT_URL` должны совпадать с именами уже запущенных контейнеров Postgres и MinIO.

2. Запустите MLflow к существующим Postgres/MinIO (сети `dbs` и `s3` уже должны существовать):

   ```bash
   podman compose -f docker/docker-compose-standalone.yml --env-file .env.mlflow up -d --build
   ```

   Полный стек со своими Postgres и MinIO:

   ```bash
   podman compose -f docker/docker-compose-full.yml --env-file .env.mlflow up -d --build
   ```

3. Проверьте доступность:

   | Сервис | URL | Учётные данные |
   | --- | --- | --- |
   | MLflow | http://localhost:5000 | без аутентификации |
   | MinIO Console | http://localhost:9001 | `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` |
   | MinIO S3 API | http://localhost:9000 | access key / secret key (см. ниже) |
   | PostgreSQL | порт `POSTGRES_PORT` | `POSTGRES_USER` / `POSTGRES_PASSWORD` |

Шаблон `.env.mlflow.example` содержит только плейсхолдеры. Для Compose MLflow ходит в Postgres и MinIO по именам хостов из `POSTGRES_HOST` и `MLFLOW_S3_ENDPOINT_URL`. Для постоянной работы лучше выпустить отдельные API-ключи MinIO, а не использовать root-учётку.

## PostgreSQL

Официальный образ создаёт базу `POSTGRES_DB` при первой инициализации тома. Она используется для tracking metadata (`MLFLOW_BACKEND_STORE_URI`).

Проверка:

```bash
podman compose -f docker/docker-compose-full.yml --env-file .env.mlflow exec postgres psql -U "$POSTGRES_USER" -c '\l'
```

Скрипты в `/docker-entrypoint-initdb.d/` выполняются только на пустом томе. Если база уже создана, смена имён в `.env.mlflow` её не пересоздаст — нужен новый том (`podman compose -f docker/docker-compose-full.yml down -v`).

## MinIO: настройка и API-ключи

MinIO поднимается вместе со стеком. `minio-init` после готовности API создаёт bucket `MLFLOW_BUCKET_NAME`, если его ещё нет.

### 1. Войти в консоль

1. Откройте http://localhost:9001
2. **Username** — значение `MINIO_ROOT_USER`
3. **Password** — значение `MINIO_ROOT_PASSWORD`

### 2. Проверить bucket

В разделе **Buckets** должен быть bucket с именем из `MLFLOW_BUCKET_NAME` (его создаёт `minio-init`). Если его нет:

1. **Create Bucket**
2. **Bucket Name**: значение `MLFLOW_BUCKET_NAME`
3. Остальные опции можно оставить по умолчанию, **Create Bucket**

Версионирование для MLflow не обязательно.

### 3. Выпустить Access Key и Secret Key

Root-учётка MinIO тоже работает как пара access/secret key, но для MLflow лучше отдельный ключ.

1. В консоли откройте **Access Keys** (иконка пользователя → **Access Keys**, либо **Identity** → **Access Keys** — зависит от версии UI)
2. **Create access key**
3. Опционально:
   - **Name** / **Description**: произвольное имя для MLflow
   - **Expiry**: без срока или с датой
   - ограничение политики только на bucket `MLFLOW_BUCKET_NAME`, если политика доступна в UI
4. **Create**
5. Скопируйте **Access Key** и **Secret Key**. Секрет показывается один раз.

### 4. Прописать ключи в MLflow

В `.env.mlflow`:

```bash
AWS_ACCESS_KEY_ID=<Access Key из консоли>
AWS_SECRET_ACCESS_KEY=<Secret Key из консоли>
AWS_DEFAULT_REGION=<AWS_DEFAULT_REGION>
MLFLOW_S3_ENDPOINT_URL=<MLFLOW_S3_ENDPOINT_URL>
MLFLOW_BUCKET_NAME=<MLFLOW_BUCKET_NAME>
```

`AWS_DEFAULT_REGION` для MinIO может быть любым непустым значением.

Перезапустите MLflow, чтобы подтянуть новые переменные:

```bash
podman compose -f docker/docker-compose-standalone.yml --env-file .env.mlflow up -d mlflow
```

### 5. Клиенты с хоста (не из Compose)

Из контейнера MLflow endpoint — значение `MLFLOW_S3_ENDPOINT_URL`. С хоста (AWS CLI, boto3, `mc`) используйте проброшенный порт API:

```bash
mc alias set local http://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"
mc ls "local/${MLFLOW_BUCKET_NAME}"
```

Или после выпуска ключей:

```bash
mc alias set mlflow http://localhost:9000 "<Access Key>" "<Secret Key>"
mc ls "mlflow/${MLFLOW_BUCKET_NAME}"
```
