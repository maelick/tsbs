if [ "$0" = "/bin/bash" ]; then
    benchmark_dir=$(pwd)
else
    benchmark_dir=$(dirname $0)
fi
source ${benchmark_dir}/common.sh

# start and wait for siridb to be ready
compose up -d siridb
while ! nc -z localhost 9000; do
    echo "Waiting for siridb to be ready..."
    sleep 1
done

cd siridb

# generate and load cpu-only data

scale=1000
gen_data cpu-only siridb $scale
load_data cpu-only siridb

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
    gen_queries cpu-only $query_type siridb $scale $num_queries
    echo "Running queries for $query_type"
    run_queries cpu-only $query_type siridb
done

# generate and load devops data

scale=100
gen_data devops siridb $scale
load_data devops siridb

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
    gen_queries devops $query_type siridb $scale $num_queries
    echo "Running queries for $query_type"
    run_queries devops $query_type siridb
done

# cleanup
compose down
docker volume rm tsbs_siridb-data