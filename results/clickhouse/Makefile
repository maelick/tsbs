ROOT_DIR := $(shell pwd)/../..
DB_NAME := $(shell basename $(shell pwd))
LOAD_OPTIONS := --chunk-time 8h0m0s --field-index-count 1 --pass postgres
RUN_OPTIONS := --pass postgres

include ../common.mk

.PHONY: wait-db
wait-db:
	@while ! docker exec -i tsbs-clickhouse-1 clickhouse-client --query="SELECT 1"; do \
		echo "Waiting for ${DB_NAME} to be ready..."; \
		sleep 1; \
	done
	@echo "${DB_NAME} is ready!"

.PHONY: data
data: cpu-only-data.gz devops-data.gz