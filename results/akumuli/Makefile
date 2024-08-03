ROOT_DIR := $(shell pwd)/../..
DB_NAME := $(shell basename $(shell pwd))
LOAD_OPTIONS := --endpoint=localhost:8282

include ../common.mk

.PHONY: wait-db
wait-db:
	@while ! curl -s http://localhost:8181/api/stats; do \
		echo "Waiting for ${DB_NAME} to be ready..."; \
		sleep 1; \
	done
	@echo "${DB_NAME} is ready!"