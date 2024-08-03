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

compose() {
    ${benchmark_dir}/compose.sh $@
}

gen_data() {
    use_case=$1
    format=$2
    scale=$3
    if [ -z "$use_case" ] || [ -z "$format" ] || [ -z "$scale" ]; then
        echo "Usage: gen_data <use_case> <format> <scale>"
        return 1
    fi
    filename="$use_case-data.gz"
    if [ ! -f $filename ]; then
        time $gen_data --use-case=$use_case --seed=123 --scale=$scale \
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
    scale=$4
    num_queries=$5
    if [ -z "$num_queries" ]; then
        num_queries=100
    fi
    if [ -z "$use_case" ] || [ -z "$query_type" ] || [ -z "$format" ] || [ -z "$scale" ]; then
        echo "Usage: gen_queries <use_case> <query_type> <format> <scale> [num_queries]"
        return 1
    fi
    mkdir -p queries
    filename="queries/$use_case-$query_type.gz"
    $gen_queries --use-case=$use_case --seed=123 --scale=1000 \
        --timestamp-start="2016-01-01T00:00:00Z" \
        --timestamp-end="2016-01-04T00:00:01Z" \
        --queries=$num_queries --query-type=$query_type --format=$format \
        | gzip > $filename
}

load_data_from_config() {
    use_case=$1
    db=$2
    if [ -z "$use_case" ] || [ -z "$db" ]; then
        echo "Usage: load_data_from_config <use_case> <db>"
        return 1
    fi
    time $tsbs_load load $db --config=./$use_case-config.yaml | tee $use_case-load.log
}

load_data() {
    use_case=$1
    db=$2
    shift 2
    if [ -z "$use_case" ] || [ -z "$db" ]; then
        echo "Usage: load_data <use_case> <db> [args]"
        return 1
    fi
    mkdir -p logs
    db_name=$(echo "benchmark_${use_case}" | tr '-' '_')
    data_file="$use_case-data.gz"
    log_file="logs/$use_case-load.log"
    result_file="$use_case-load.json"
    time ${tsbs_load}_${db} --workers=2 --batch-size=10000 --db-name=$db_name --file $data_file --results-file $result_file "$@" | tee $log_file
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
    mkdir -p logs
    db_name=$(echo "benchmark_${use_case}" | tr '-' '_')
    filename="$use_case-$query_type"
    tsbs_run="${bin_dir}/tsbs_run_queries_$db"
    result_file="$filename.json"
    time $tsbs_run --workers=1 --file "queries/$filename.gz" --db-name $db_name "$@" --results-file $result_file | tee "logs/$filename.log"
}