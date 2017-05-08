#! /bin/bash

redis_dir="${SNAP_DATA}/redis"
redis_conf_name="${redis_dir}/redis.conf"

if [[ ! -f ${redis_conf_name} ]]
then
    mkdir -p "${redis_dir}"
    cp ${SNAP}/bin/redis.conf ${redis_dir}
fi

redis-server ${redis_conf_name}

