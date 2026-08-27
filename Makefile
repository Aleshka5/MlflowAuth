COMPOSE       ?= podman compose
ENV_FILE      ?= .env.mlflow
COMPOSE_FULL  := docker/docker-compose-full.yml
COMPOSE_STAND := docker/docker-compose-standalone.yml

FULL_CONTAINERS := mlflow-server mlflow-postgres mlflow-minio mlflow-minio-init

.PHONY: help \
	up-full up-standalone up-standalong up-full-no-auth up-standalone-no-auth \
	down-full down-standalone down-mlflow down-full-no-auth down-standalone-no-auth down-all

help:
	@echo "make up-full                  Start full stack with auth"
	@echo "make up-standalone            Start mlflow only with auth"
	@echo "make up-full-no-auth          Start full stack without auth"
	@echo "make up-standalone-no-auth    Start mlflow only without auth"
	@echo "make down-full                Stop full stack (auth)"
	@echo "make down-standalone          Stop standalone mlflow (auth)"
	@echo "make down-full-no-auth        Stop full stack (no-auth)"
	@echo "make down-standalone-no-auth  Stop standalone mlflow (no-auth)"
	@echo "make down-all                 Stop every mlflow compose project and container"

up-full:
	-podman rm -f $(FULL_CONTAINERS)
	MLFLOW_AUTH_ENABLED=true $(COMPOSE) -p mlflow-full -f $(COMPOSE_FULL) --env-file $(ENV_FILE) up -d --build --force-recreate

up-standalone:
	-podman rm -f mlflow-server
	MLFLOW_AUTH_ENABLED=true $(COMPOSE) -p mlflow-standalone -f $(COMPOSE_STAND) --env-file $(ENV_FILE) up -d --build --force-recreate

up-standalong: up-standalone

up-full-no-auth:
	-podman rm -f $(FULL_CONTAINERS)
	MLFLOW_AUTH_ENABLED=false $(COMPOSE) -p mlflow-full-noauth -f $(COMPOSE_FULL) --env-file $(ENV_FILE) up -d --build --force-recreate

up-standalone-no-auth:
	-podman rm -f mlflow-server
	MLFLOW_AUTH_ENABLED=false $(COMPOSE) -p mlflow-standalone-noauth -f $(COMPOSE_STAND) --env-file $(ENV_FILE) up -d --build --force-recreate

down-full:
	-$(COMPOSE) -p mlflow-full -f $(COMPOSE_FULL) --env-file $(ENV_FILE) down
	-podman rm -f $(FULL_CONTAINERS)

down-standalone:
	-$(COMPOSE) -p mlflow-standalone -f $(COMPOSE_STAND) --env-file $(ENV_FILE) down
	-podman rm -f mlflow-server

down-mlflow: down-standalone

down-full-no-auth:
	-$(COMPOSE) -p mlflow-full-noauth -f $(COMPOSE_FULL) --env-file $(ENV_FILE) down
	-podman rm -f $(FULL_CONTAINERS)

down-standalone-no-auth:
	-$(COMPOSE) -p mlflow-standalone-noauth -f $(COMPOSE_STAND) --env-file $(ENV_FILE) down
	-podman rm -f mlflow-server

down-all: down-full down-standalone down-full-no-auth down-standalone-no-auth
