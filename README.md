# MlflowAuth

Минимальная Podman-сборка MLflow Server с Basic Auth, PostgreSQL backend-store и MinIO (S3) для артефактов.

## Состав проекта

- `docker/Dockerfile` — образ Python 3.11 с `mlflow[auth]`, `boto3`, `psycopg2-binary`.
- `scripts/start.sh` — запуск `mlflow server`; при `MLFLOW_AUTH_ENABLED=true` пишет `basic_auth.ini` и включает `--app-name basic-auth`.
- `docker/docker-compose-standalone.yml` — только `mlflow`, внешние сети `dbs` (Postgres) и `s3` (MinIO).
- `docker/docker-compose-full.yml` — полный стек: `mlflow`, `postgres`, `minio` и одноразовый `minio-init`.
- `scripts/init-databases.sh` — создание баз `mlflow` и `auth` при первом старте Postgres (полный стек).
- `scripts/init-bucket.sh` — создание bucket `MLFLOW_BUCKET_NAME` после старта MinIO (полный стек).
- `.env.mlflow` — параметры подключения (создать по шаблону `.env.mlflow.example`).

## Быстрый старт

1. Подготовьте файл окружения:

   ```bash
   cp .env.mlflow.example .env.mlflow
   ```

   Для standalone `POSTGRES_HOST` и `MLFLOW_S3_ENDPOINT_URL` должны совпадать с именами уже запущенных контейнеров Postgres и MinIO.

2. Запустите стек через Makefile (`make help` — полный список). По умолчанию на `main` — Basic Auth; цели `*-no-auth` поднимают тот же стек без логина.

   | Команда | Что поднимает |
   | --- | --- |
   | `make up-full` | полный стек с auth |
   | `make up-standalone` | только MLflow с auth (внешние Postgres/MinIO) |
   | `make up-full-no-auth` | полный стек без auth |
   | `make up-standalone-no-auth` | только MLflow без auth |
   | `make down-full` / `down-standalone` / `down-full-no-auth` / `down-standalone-no-auth` | остановка соответствующего варианта |
   | `make down-all` | остановить все варианты |

   Auth и no-auth используют одни и те же имена контейнеров (`mlflow-server` и т.д.) — одновременно их не держать. Перед `up-*` Makefile удаляет конфликтующие контейнеры.

3. Проверьте доступность:

   | Сервис | URL | Учётные данные |
   | --- | --- | --- |
   | MLflow | http://localhost:5000 | `admin` / `admin_password` (только auth; no-auth — без логина) |
   | MinIO Console | http://localhost:9001 | `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` |
   | MinIO S3 API | http://localhost:9000 | access key / secret key (см. ниже) |
   | PostgreSQL | `localhost:5432` | `POSTGRES_USER` / `POSTGRES_PASSWORD` |

Шаблон `.env.mlflow.example` рассчитан на локальный Compose: MLflow ходит в Postgres и MinIO по именам сервисов (`postgres`, `minio`). Для быстрого старта `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` совпадают с root-учёткой MinIO. Для постоянной работы лучше выпустить отдельные API-ключи.

## PostgreSQL

Официальный образ создаёт базу `POSTGRES_DB` (`mlflow`). Скрипт `scripts/init-databases.sh` при **первой** инициализации тома дополнительно создаёт `POSTGRES_AUTH_DB` (`auth`).

- `mlflow` — tracking metadata (`MLFLOW_BACKEND_STORE_URI`)
- `auth` — пользователи и права Basic Auth (`MLFLOW_AUTH_DB_URI`)

Проверка:

```bash
podman compose -f docker/docker-compose-full.yml --env-file .env.mlflow exec postgres psql -U mlflow -c '\l'
```

Скрипты в `/docker-entrypoint-initdb.d/` выполняются только на пустом томе. Если базы уже созданы, смена имён в `.env.mlflow` их не пересоздаст — нужен новый том (`podman compose -f docker/docker-compose-full.yml down -v`).

## MinIO: настройка и API-ключи

MinIO поднимается вместе со стеком. `minio-init` после готовности API создаёт bucket `MLFLOW_BUCKET_NAME` (`mlflow`), если его ещё нет.

### 1. Войти в консоль

1. Откройте http://localhost:9001
2. **Username** — значение `MINIO_ROOT_USER` (по умолчанию `minioadmin`)
3. **Password** — значение `MINIO_ROOT_PASSWORD` (по умолчанию `minioadmin`)

### 2. Проверить bucket

В разделе **Buckets** должен быть bucket `mlflow` (его создаёт `minio-init`). Если его нет:

1. **Create Bucket**
2. **Bucket Name**: `mlflow` (должно совпадать с `MLFLOW_BUCKET_NAME`)
3. Остальные опции можно оставить по умолчанию, **Create Bucket**

Версионирование для MLflow не обязательно.

### 3. Выпустить Access Key и Secret Key

Root-учётка MinIO тоже работает как пара access/secret key, но для MLflow лучше отдельный ключ.

1. В консоли откройте **Access Keys** (иконка пользователя → **Access Keys**, либо **Identity** → **Access Keys** — зависит от версии UI)
2. **Create access key**
3. Опционально:
   - **Name** / **Description**: `mlflow`
   - **Expiry**: без срока или с датой
   - ограничение политики только на bucket `mlflow`, если политика доступна в UI
4. **Create**
5. Скопируйте **Access Key** и **Secret Key**. Секрет показывается один раз.

### 4. Прописать ключи в MLflow

В `.env.mlflow`:

```bash
AWS_ACCESS_KEY_ID=<Access Key из консоли>
AWS_SECRET_ACCESS_KEY=<Secret Key из консоли>
AWS_DEFAULT_REGION=us-east-1
MLFLOW_S3_ENDPOINT_URL=http://minio:9000
MLFLOW_BUCKET_NAME=mlflow
```

`AWS_DEFAULT_REGION` для MinIO может быть любым непустым значением; `us-east-1` — обычный выбор.

Перезапустите MLflow, чтобы подтянуть новые переменные:

```bash
podman compose -f docker/docker-compose-standalone.yml --env-file .env.mlflow up -d mlflow
```

### 5. Клиенты с хоста (не из Compose)

Из контейнера MLflow endpoint — `http://minio:9000`. С хоста (AWS CLI, boto3, `mc`) используйте `http://localhost:9000`:

```bash
mc alias set local http://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"
mc ls local/mlflow
```

Или после выпуска ключей:

```bash
mc alias set mlflow http://localhost:9000 "<Access Key>" "<Secret Key>"
mc ls mlflow/mlflow
```
