#!/bin/bash

service cron start

_term() {
  kill -INT "$forecastic" 2>/dev/null
  wait "$forecastic"
}

trap _term SIGTERM SIGINT

is_eureka_opt=false
eureka_host=eureka

for var in "$@"; do
    if [ "$var" = "--eureka" ]; then
        is_eureka_opt=true
    fi

    if $is_eureka_opt; then
        eureka_host="$var"
    fi
done

./wait-for-it.sh -t 120 $eureka_host:8761

Rscript R/main.R --host $(ip address | grep inet.*eth0 | sed -r 's/.*inet ([0-9\.]+).*/\1/') --port 80 --name forecastic --eureka $eureka_host --elastic elasticsearch $@ &

forecastic=$! 
wait "$forecastic"