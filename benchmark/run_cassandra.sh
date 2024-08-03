if [ "$0" = "/bin/bash" ]; then
    benchmark_dir=$(pwd)
else
    benchmark_dir=$(dirname $0)
fi
source ${benchmark_dir}/common.sh

# start and wait for cassandra to be ready
compose up -d cassandra
while ! docker exec -i tsbs-cassandra-1 cqlsh -e "DESCRIBE KEYSPACES" 2>/dev/null; do
    echo "Waiting for cassandra to be ready..."
    sleep 1
done

cd cassandra

# generate and load cpu-only data

scale=1000
gen_data cpu-only cassandra $scale
load_data cpu-only cassandra

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
    gen_queries cpu-only $query_type cassandra $scale $num_queries
    echo "Running queries for $query_type"
    run_queries cpu-only $query_type cassandra
done

# generate and load devops data

scale=100
gen_data devops cassandra $scale
load_data devops cassandra

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
    gen_queries devops $query_type cassandra $scale $num_queries
    echo "Running queries for $query_type"
    run_queries devops $query_type cassandra
done

# cleanup
compose down
docker volume rm tsbs_cassandra-data