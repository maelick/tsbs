ROOT_DIR := $(shell pwd)/../..
DB_NAME := $(shell basename $(shell pwd))

include ../common.mk

.PHONY: wait-db
wait-db:
	@while ! docker exec -i tsbs-cratedb-1 curl -s http://localhost:4200; do \
		echo "Waiting for ${DB_NAME} to be ready..."; \
		sleep 1; \
	done
	@echo "${DB_NAME} is ready!"

.PHONY: data
data: cpu-only-data.gz devops-data.gz

.PHONY: load-data
load-data: load-cpu-only load-devops

.PHONY: run-queries
run-queries: run-cpu-only run-devops