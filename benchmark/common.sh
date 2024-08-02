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

gen_data() {
    use_case=$1
    format=$2
    if [ -z "$use_case" ]; then
        echo "Usage: gen_data <use_case> <format>"
        return 1
    fi
    filename="$use_case-data.gz"
    if [ ! -f $filename ]; then
        time $gen_data --use-case=$use_case --seed=123 --scale=1000 \
            --timestamp-start="2016-01-01T00:00:00Z" \
            --timestamp-end="2016-01-04T00:00:00Z" \
            --log-interval="10s" --format=$format \
            | gzip > $filename
    fi
}

gen_queries() {
    use_case=$1
    query_type=$2
    format=$3
    num_queries=$4
    if [ -z "$num_queries" ]; then
        num_queries=100
    fi
    if [ -z "$use_case" ] || [ -z "$query_type" ] || [ -z "$format" ]; then
        echo "Usage: gen_queries <use_case> <query_type> <format> [num_queries]"
        return 1
    fi
    filename="$use_case-queries-$query_type.gz"
    time $gen_queries --use-case=$use_case --seed=123 --scale=1000 \
        --timestamp-start="2016-01-01T00:00:00Z" \
        --timestamp-end="2016-01-04T00:00:01Z" \
        --queries=$num_queries --query-type=$query_type --format=$format \
        | gzip > $filename
}

load_data() {
    use_case=$1
    db=$2
    if [ -z "$use_case" ] || [ -z "$db" ]; then
        echo "Usage: load_data <use_case> <db>"
        return 1
    fi
    time $tsbs_load load $db --config=./$use_case-config.yaml | tee $use_case-load.log
}

run_queries() {
    use_case=$1
    query_type=$2
    db=$3
    shift 3
    if [ -z "$use_case" ] || [ -z "$query_type" ] || [ -z "$db" ]; then
        echo "Usage: run_queries <use_case> <query_type> <db> [args]"
        return 1
    fi
    filename="$use_case-queries-$query_type"
    tsbs_run="${bin_dir}/tsbs_run_queries_$db"
    time (cat "$filename.gz" | gunzip | $tsbs_run --workers=1 "$@") | tee "$filename.log"
}