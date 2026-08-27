FROM docker.io/library/python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN pip install --no-cache-dir \
    "mlflow[auth]==3.15.0" \
    boto3 \
    psycopg2-binary

WORKDIR /app

COPY scripts/start.sh /app/scripts/start.sh
