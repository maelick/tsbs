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

cd timescaledb

# generate data and queries

gen_data iot timescaledb
gen_queries iot breakdown-frequency timescaledb

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

load_data iot timescaledb
run_queries iot breakdown-frequency --postgres="host=localhost user=postgres password=postgres sslmode=disable"

# cleanup
docker compose down
docker volume rm benchmark_timescaledb-data