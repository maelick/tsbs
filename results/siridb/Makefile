ROOT_DIR := $(shell pwd)/../..
DB_NAME := $(shell basename $(shell pwd))
LOAD_OPTIONS := --chunk-time 8h0m0s --field-index-count 1 --pass postgres
RUN_OPTIONS := --pass postgres

include ../common.mk

.PHONY: wait-db
wait-db:
	@while ! nc -z localhost 9000; do \
		echo "Waiting for ${DB_NAME} to be ready..."; \
		sleep 1; \
	done
	@echo "${DB_NAME} is ready!"