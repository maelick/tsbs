compose_dir=$(dirname $0)
compose_file=${compose_dir}/compose.yaml
docker compose -f $compose_file -p tsbs "$@"