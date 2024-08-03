BIN_DIR := $(ROOT_DIR)/bin
SCRIPT_DIR := $(ROOT_DIR)/scripts
COMPOSE := $(SCRIPT_DIR)/compose.sh
GEN_DATA := $(BIN_DIR)/tsbs_generate_data
GEN_QUERIES := $(BIN_DIR)/tsbs_generate_queries
LOAD_DATA := $(BIN_DIR)/tsbs_load
RUN_QUERIES := $(BIN_DIR)/tsbs_run_queries

CPU_ONLY_SCALE ?= 10
DEVOPS_SCALE ?= 10
IOT_SCALE ?= 10
SEED ?= 123
START ?= 2016-01-01T00:00:00Z
END ?= 2016-01-02T00:00:00Z
QUERIES_END ?= 2016-01-02T00:00:01Z
INTERVAL ?= 10s
NUM_QUERIES ?= 100
NUM_WORKERS_LOAD ?= 2
NUM_WORKERS_RUN ?= 1
BATCH_SIZE ?= 10000

CPU_ONLY_QUERIES ?= \
	single-groupby-1-1-1 single-groupby-1-1-12 single-groupby-1-8-1 \
	single-groupby-5-1-1 single-groupby-5-1-12 single-groupby-5-8-1 \
	cpu-max-all-1 cpu-max-all-8 \
	double-groupby-1 double-groupby-5 double-groupby-all \
	high-cpu-all high-cpu-1 lastpoint groupby-orderby-limit

DEVOPS_QUERIES ?= \
	single-groupby-1-1-1 single-groupby-1-1-12 single-groupby-1-8-1 \
	single-groupby-5-1-1 single-groupby-5-1-12 single-groupby-5-8-1 \
	cpu-max-all-1 cpu-max-all-8 \
	double-groupby-1 double-groupby-5 double-groupby-all \
	high-cpu-all high-cpu-1 lastpoint groupby-orderby-limit

IOT_QUERIES ?= \
	last-loc low-fuel high-load stationary-trucks \
	long-driving-sessions long-daily-sessions \
	avg-vs-projected-fuel-consumption \
	avg-daily-driving-duration avg-daily-driving-session \
	avg-load daily-activity breakdown-frequency

.PHONY: clean-data
clean-data:
	rm *-data.gz

.PHONY: clean-queries
clean-queries:
	rm queries/*.gz
	
.PHONY: clean-volume
clean-volume: down
	docker volume rm tsbs_influx-data

.PHONY: data
data: cpu-only-data.gz devops-data.gz iot-data.gz

.PHONY: ready
ready: up wait-db

.PHONY: up
up:
	${COMPOSE} up -d ${DB_NAME}

.PHONY: down
down:
	${COMPOSE} down ${DB_NAME}

.PHONY: devops-queries
devops-queries: $(foreach query,$(DEVOPS_QUERIES),queries/devops-$(query).gz)

.PHONY: cpu-only-queries
cpu-only-queries: $(foreach query,$(CPU_ONLY_QUERIES),queries/cpu-only-$(query).gz)

.PHONY: iot-queries
iot-queries: $(foreach query,$(IOT_QUERIES),queries/iot-$(query).gz)

.PHONY: run-cpu-only
run-cpu-only: $(foreach query,$(CPU_ONLY_QUERIES),run-cpu-only-$(query))

.PHONY: run-devops
run-devops: $(foreach query,$(DEVOPS_QUERIES),run-devops-$(query))

.PHONY: run-iot
run-iot: $(foreach query,$(IOT_QUERIES),run-iot-$(query))

.PHONY: load-%
load-%: ready %-data.gz
	@echo "Loading $* data for ${DB_NAME}"
	mkdir -p logs
	${LOAD_DATA}_${DB_NAME} \
		--workers=${NUM_WORKERS_LOAD} \
		--batch-size=${BATCH_SIZE} \
		--db-name=benchmark_$(shell echo $* | tr '-' '_') \
		--file "$*-data.gz" \
		--results-file "$*-load.json" \
		${LOAD_OPTIONS} | tee "logs/$*-load.log"

.PHONY: run-cpu-only-%
run-cpu-only-%: ready queries/cpu-only-%.gz
	@echo "Running $* queries for ${DB_NAME}"
	mkdir -p logs
	${RUN_QUERIES}_${DB_NAME} \
		--workers=${NUM_WORKERS_RUN} \
		--db-name=benchmark_cpu_only \
		--file "queries/cpu-only-$*.gz" \
		--results-file "cpu-only-$*.json" \
		${RUN_OPTIONS} | tee "logs/cpu-only-$*.log"

.PHONY: run-devops-%
run-devops-%: ready queries/devops-%.gz
	@echo "Running $* queries for ${DB_NAME}"
	mkdir -p logs
	${RUN_QUERIES}_${DB_NAME} \
		--workers=${NUM_WORKERS_RUN} \
		--db-name=benchmark_devops \
		--file "queries/devops-$*.gz" \
		--results-file "devops-$*.json" \
		${RUN_OPTIONS} | tee "logs/devops-$*.log"

.PHONY: run-iot-%
run-iot-%: ready queries/iot-%.gz
	@echo "Running $* queries for ${DB_NAME}"
	mkdir -p logs
	${RUN_QUERIES}_${DB_NAME} \
		--workers=${NUM_WORKERS_RUN} \
		--db-name=benchmark_iot \
		--file "queries/iot-$*.gz" \
		--results-file "iot-$*.json" \
		${RUN_OPTIONS} | tee "logs/iot-$*.log"

%-data.gz:
	@echo "Generating $* data for ${DB_NAME}"
	$(eval SCALE := $(shell echo $* | sed 's/cpu-only/${CPU_ONLY_SCALE}/;s/devops/${DEVOPS_SCALE}/;s/iot/${IOT_SCALE}/'))
	${GEN_DATA} \
		--use-case=$* \
		--seed=${SEED} \
		--scale=${SCALE} \
		--timestamp-start="${START}" \
		--timestamp-end="${END}" \
		--log-interval="${INTERVAL}" \
		--format="${DB_NAME}" \
		--file "$@"

queries/cpu-only-%.gz:
	@echo "Generating cpu-only $* queries for ${DB_NAME}"
	@mkdir -p queries
	${GEN_QUERIES} \
		--use-case=cpu-only \
		--seed=${SEED} \
		--scale=${CPU_ONLY_SCALE} \
		--timestamp-start="${START}" \
		--timestamp-end="${QUERIES_END}" \
        --queries=${NUM_QUERIES} \
		--query-type=$* \
		--format=${DB_NAME} \
		--file "$@"

queries/devops-%.gz:
	@echo "Generating devops $* queries for ${DB_NAME}"
	@mkdir -p queries
	${GEN_QUERIES} \
		--use-case=devops \
		--seed=${SEED} \
		--scale=${DEVOPS_SCALE} \
		--timestamp-start="${START}" \
		--timestamp-end="${QUERIES_END}" \
        --queries=${NUM_QUERIES} \
		--query-type=$* \
		--format=${DB_NAME} \
		--file "$@"

queries/iot-%.gz:
	@echo "Generating iot $* queries for ${DB_NAME}"
	@mkdir -p queries
	${GEN_QUERIES} \
		--use-case=iot \
		--seed=${SEED} \
		--scale=${IOT_SCALE} \
		--timestamp-start="${START}" \
		--timestamp-end="${QUERIES_END}" \
        --queries=${NUM_QUERIES} \
		--query-type=$* \
		--format=${DB_NAME} \
		--file "$@"