ROOT_DIR := $(shell pwd)/../..
DB_NAME := $(shell basename $(shell pwd))

include ../common.mk

.PHONY: wait-db
wait-db:
	@while ! curl -s localhost:9000 2>&1 > /dev/null; do \
		echo "Waiting for ${DB_NAME} to be ready..."; \
		sleep 1; \
	done
	@echo "${DB_NAME} is ready!"

# FIXME missing results-file, db-name
.PHONY: load-%
load-%: ready %-data.gz
	@echo "Loading $* data for ${DB_NAME}"
	mkdir -p logs
	${LOAD_DATA}_${DB_NAME} \
		--workers=${NUM_WORKERS_LOAD} \
		--batch-size=${BATCH_SIZE} \
		--file "$*-data.gz" \
		${LOAD_OPTIONS} | tee "logs/$*-load.log"

.PHONY: data
data: cpu-only-data.gz devops-data.gz iot-data.gz

.PHONY: load-data
load-data: load-cpu-only load-devops load-iot

.PHONY: run-queries
run-queries: run-cpu-only run-devops run-iot