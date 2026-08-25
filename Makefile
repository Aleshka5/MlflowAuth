COMPOSE       ?= podman compose
ENV_FILE      ?= .env.mlflow
COMPOSE_FULL  := docker/docker-compose-full.yml
COMPOSE_STAND := docker/docker-compose-standalone.yml

.PHONY: help up-full up-standalone up-standalong down-full down-mlflow

help:
	@echo "make up-full          Start full stack (replace existing containers)"
	@echo "make up-standalone    Start mlflow only (replace mlflow-server)"
	@echo "make down-full        Stop full stack"
	@echo "make down-mlflow      Stop mlflow container only"

up-full:
	-podman rm -f mlflow-server mlflow-postgres mlflow-minio mlflow-minio-init
	$(COMPOSE) -p mlflow-full -f $(COMPOSE_FULL) --env-file $(ENV_FILE) up -d --build --force-recreate

up-standalone:
	-podman rm -f mlflow-server
	$(COMPOSE) -p mlflow-standalone -f $(COMPOSE_STAND) --env-file $(ENV_FILE) up -d --build --force-recreate

up-standalong: up-standalone

down-full:
	-$(COMPOSE) -p mlflow-full -f $(COMPOSE_FULL) --env-file $(ENV_FILE) down
	-podman rm -f mlflow-server mlflow-postgres mlflow-minio mlflow-minio-init

down-mlflow:
	-$(COMPOSE) -p mlflow-standalone -f $(COMPOSE_STAND) --env-file $(ENV_FILE) down
	-podman rm -f mlflow-server
