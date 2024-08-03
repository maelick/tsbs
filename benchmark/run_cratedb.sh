if [ "$0" = "/bin/bash" ]; then
    benchmark_dir=$(pwd)
else
    benchmark_dir=$(dirname $0)
fi
source ${benchmark_dir}/common.sh

# start and wait for cratedb to be ready
compose up -d cratedb
while ! docker exec -i tsbs-cratedb-1 curl -s http://localhost:4200; do
    echo "Waiting for cratedb to be ready..."
    sleep 1
done

cd cratedb

# generate and load cpu-only data

scale=1000
gen_data cpu-only cratedb $scale
load_data cpu-only cratedb

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
    gen_queries cpu-only $query_type cratedb $scale $num_queries
    echo "Running queries for $query_type"
    run_queries cpu-only $query_type cratedb
done

# generate and load devops data

scale=100
gen_data devops cratedb $scale
load_data devops cratedb

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
    gen_queries devops $query_type cratedb $scale $num_queries
    echo "Running queries for $query_type"
    run_queries devops $query_type cratedb
done

# cleanup
compose down
docker volume rm tsbs_cratedb-data