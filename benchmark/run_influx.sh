if [ "$0" = "/bin/bash" ]; then
    benchmark_dir=$(pwd)
else
    benchmark_dir=$(dirname $0)
fi
source ${benchmark_dir}/common.sh

# start and wait for influx to be ready
compose up -d influx
while ! curl -s localhost:8086/ping 2>&1 > /dev/null; do
    echo "Waiting for influx to be ready..."
    sleep 1
done

cd influx

# generate and load cpu-only data

scale=1000
gen_data cpu-only influx $scale
load_data cpu-only influx

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
    gen_queries cpu-only $query_type influx $scale $num_queries
    echo "Running queries for $query_type"
    run_queries cpu-only $query_type influx
done

# generate and load devops data

scale=100
gen_data devops influx $scale
load_data devops influx

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
    gen_queries devops $query_type influx $scale $num_queries
    echo "Running queries for $query_type"
    run_queries devops $query_type influx
done

# generate and load iot data

scale=1000
gen_data iot influx $scale
load_data iot influx

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
    gen_queries iot $query_type influx $scale $num_queries
    echo "Running queries for $query_type"
    run_queries iot $query_type influx
done

# cleanup
compose down
docker volume rm tsbs_influx-data