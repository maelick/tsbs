if [ "$0" = "/bin/bash" ]; then
    benchmark_dir=$(pwd)
else
    benchmark_dir=$(dirname $0)
fi
source ${benchmark_dir}/common.sh

# start and wait for timescaledb to be ready
compose up -d timescaledb
while ! docker exec -i tsbs-timescaledb-1 pg_isready -U postgres; do
    echo "Waiting for postgres to be ready..."
    sleep 1
done

psql() {
    if [ -z "$1" ] || [ "$1" = "-t" ]; then
        shift 1
        docker exec -it tsbs-timescaledb-1 psql -U postgres "$@"
    else
        docker exec -i tsbs-timescaledb-1 psql -U postgres "$@"
    fi
}

cd timescaledb

# generate and load cpu-only data

scale=1000
gen_data cpu-only timescaledb $scale
psql -d postgres -c "DROP DATABASE IF EXISTS benchmark_cpu_only;"
load_data cpu-only timescaledb --chunk-time 8h0m0s --field-index-count 1 --pass postgres

# generate and run queries

query_types="
    single-groupby-1-1-1 single-groupby-1-1-12 single-groupby-1-8-1
    single-groupby-5-1-1 single-groupby-5-1-12 single-groupby-5-8-1
    cpu-max-all-1 cpu-max-all-8
    double-groupby-1 double-groupby-5 double-groupby-all
    high-cpu-all high-cpu-1 lastpoint groupby-orderby-limit
"

num_queries=100
for query_type in $query_types; do
    echo "Generating queries for $query_type"
    gen_queries cpu-only $query_type timescaledb $scale $num_queries
    echo "Running queries for $query_type"
    run_queries cpu-only $query_type timescaledb --pass postgres
done

# generate and load devops data

scale=100
gen_data devops timescaledb $scale
psql -d postgres -c "DROP DATABASE IF EXISTS benchmark-devops;"
load_data devops timescaledb --chunk-time 8h0m0s --field-index-count 1 --pass postgres

# generate and run queries

query_types="
    single-groupby-1-1-1 single-groupby-1-1-12 single-groupby-1-8-1
    single-groupby-5-1-1 single-groupby-5-1-12 single-groupby-5-8-1
    cpu-max-all-1 cpu-max-all-8
    double-groupby-1 double-groupby-5 double-groupby-all
    high-cpu-all high-cpu-1 lastpoint groupby-orderby-limit
"

num_queries=100
for query_type in $query_types; do
    echo "Generating queries for $query_type"
    gen_queries devops $query_type timescaledb $scale $num_queries
    echo "Running queries for $query_type"
    run_queries devops $query_type timescaledb --pass postgres
done

# generate and load iot data

scale=1000
gen_data iot timescaledb $scale
psql -d postgres -c "DROP DATABASE IF EXISTS benchmark-iot;"
load_data iot timescaledb --chunk-time 8h0m0s --field-index-count 1 --pass postgres

# generate and run queries

query_types="
    last-loc low-fuel high-load stationary-trucks
    long-driving-sessions long-daily-sessions
    avg-vs-projected-fuel-consumption
    avg-daily-driving-duration avg-daily-driving-session
    avg-load daily-activity breakdown-frequency
"

num_queries=100
for query_type in $query_types; do
    echo "Generating queries for $query_type"
    gen_queries iot $query_type timescaledb $scale $num_queries
    echo "Running queries for $query_type"
    run_queries iot $query_type timescaledb --pass postgres
done

# cleanup
compose down
docker volume rm tsbs_timescaledb-data