if [ "$0" = "/bin/bash" ]; then
    benchmark_dir=$(pwd)
else
    benchmark_dir=$(dirname $0)
fi
source ${benchmark_dir}/common.sh

# start and wait for timescaledb to be ready
docker compose up -d timescaledb
container_name="$(basename $(pwd))-timescaledb-1"
while ! docker exec -i $container_name pg_isready -U postgres; do
    echo "Waiting for postgres to be ready..."
    sleep 1
done

psql() {
    if [ -z "$1" ] || [ "$1" = "-t" ]; then
        shift 1
        docker exec -it $container_name psql -U postgres "$@"
    else
        docker exec -i $container_name psql -U postgres "$@"
    fi
}

cd timescaledb

# generate and load iot data

scale=1000
gen_data iot timescaledb $scale
psql -d postgres -c "DROP DATABASE IF EXISTS benchmark-iot;"
load_data iot timescaledb

# generate and run queries

query_types="
    last-loc low-fuel high-load stationary-trucks
    long-driving-sessions long-daily-sessions
    avg-vs-projected-fuel-consumption
    avg-daily-driving-duration avg-daily-driving-session
    avg-load daily-activity breakdown-frequency
"

num_queries=10
for query_type in $query_types; do
    echo "Generating queries for $query_type"
    gen_queries iot $query_type timescaledb $scale $num_queries
    echo "Running queries for $query_type"
    run_queries iot $query_type timescaledb --postgres="host=localhost user=postgres password=postgres database=benchmark_iot sslmode=disable"
done

# cleanup
docker compose down
docker volume rm benchmark_timescaledb-data