.DEFAULT_GOAL := help
help:
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

build: ## builds docker images
	docker-compose -f local.yml build

up: ## gets orchestration up and running
	docker-compose -f local.yml up

down: ## turns off the instances
	docker-compose -f local.yml down

airflow-sh: ## gets orchestration up and running
	docker-compose -f local.yml run airflow bash
