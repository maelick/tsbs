if [ "$0" = "/bin/bash" ]; then
    benchmark_dir=$(pwd)
else
    benchmark_dir=$(dirname $0)
fi
source ${benchmark_dir}/common.sh

# start and wait for questdb to be ready
compose up -d questdb
while ! curl -s localhost:9000 2>&1 > /dev/null; do
    echo "Waiting for questdb to be ready..."
    sleep 1
done

cd questdb

# generate and load cpu-only data

load_data_questdb() {
    data_file="$1-data.gz"
    log_file="$1-load.log"
    shift 1
    time ${tsbs_load}_questdb --workers=2 --batch-size=10000 --file $data_file "$@" | tee $log_file
}

scale=1000
gen_data cpu-only questdb $scale
load_data_questdb cpu-only

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
    gen_queries cpu-only $query_type questdb $scale $num_queries
    echo "Running queries for $query_type"
    run_queries cpu-only $query_type questdb
    break
done

# generate and load devops data

scale=100
gen_data devops questdb $scale
load_data_questdb cpu-only

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
    gen_queries devops $query_type questdb $scale $num_queries
    echo "Running queries for $query_type"
    run_queries devops $query_type questdb
done

# generate and load iot data

scale=1000
gen_data iot questdb $scale
load_data_questdb cpu-only

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
    gen_queries iot $query_type questdb $scale $num_queries
    echo "Running queries for $query_type"
    run_queries iot $query_type questdb
done

# cleanup
compose down
docker volume rm tsbs_questdb-data