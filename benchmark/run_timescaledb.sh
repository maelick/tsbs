if [ "$0" = "/bin/bash" ]; then
    benchmark_dir=$(pwd)
else
    benchmark_dir=$(dirname $0)
fi
bin_dir=${benchmark_dir}/../bin
scripts_dir=${benchmark_dir}/../scripts
gen_data=${bin_dir}/tsbs_generate_data
gen_queries=${bin_dir}/tsbs_generate_queries
tsbs_load=${bin_dir}/tsbs_load
load_script=${scripts_dir}/load/load_timescaledb.sh
tsbs_run=${bin_dir}/tsbs_run_queries_timescaledb

# start and wait for timescaledb to be ready
docker compose up -d timescaledb
container_name="$(basename $(pwd))-timescaledb-1"
while ! docker exec -i $container_name pg_isready -U postgres; do
    echo "Waiting for postgres to be ready..."
    sleep 1
done

cd timescaledb

# generate data and queries if missing

if [ ! -f "timescaledb/iot-data.gz" ]; then
    time $gen_data --use-case="iot" --seed=123 --scale=1000 \
        --timestamp-start="2016-01-01T00:00:00Z" \
        --timestamp-end="2016-01-04T00:00:00Z" \
        --log-interval="10s" --format="timescaledb" \
        | gzip > iot-data.gz
fi

if [ ! -f "timescaledb/iot-queries-breakdown-frequency.gz" ]; then
    time $gen_queries --use-case="iot" --seed=123 --scale=1000 \
        --timestamp-start="2016-01-01T00:00:00Z" \
        --timestamp-end="2016-01-04T00:00:01Z" \
        --queries=1000 --query-type="breakdown-frequency" --format="timescaledb" \
        | gzip > iot-queries-breakdown-frequency.gz
fi

psql() {
    if [ -z "$1" ] || [ "$1" = "-t" ]; then
        shift 1
        docker exec -it $container_name psql -U postgres "$@"
    else
        docker exec -i $container_name psql -U postgres "$@"
    fi
}

# drop existing database and load data
psql -d postgres -c "DROP DATABASE IF EXISTS benchmark;"

time $tsbs_load load timescaledb --config=./iot-config.yaml | tee iot-load.log

time (cat iot-queries-breakdown-frequency.gz | \
    gunzip | $tsbs_run --workers=1 \
        --postgres="host=localhost user=postgres password=postgres sslmode=disable") | tee iot-queries-breakdown-frequency.log

# cleanup
docker compose down
docker volume rm benchmark_timescaledb-data