#!/usr/bin/env bash
set -exu

pkill cf || true

msg_count=0
for i in `seq 1 $NUM_APPS`; do
    c=$(cat output-$i.txt | grep -c 'msg')
    : $(( msg_count = $msg_count + $c ))
done;

drain_domain=$(cf app ${DRAIN_TYPE}-drain | grep urls | awk '{print $2}')
drain_count=$(curl $drain_domain/count)

currenttime=$(date +%s)

curl -X POST -H "Content-type: application/json" \
-d "$(cat <<JSON
{
    "series" :
       [{"metric":"smoke_test.ss${METRIC_PREFIX}.loggregator.msg_count",
        "points":[[${currenttime}, ${msg_count}]],
        "type":"gauge",
        "host":"${CF_SYSTEM_DOMAIN}",
        "tags":["drain_version:${DRAIN_VERSION}", "drain_type:${DRAIN_TYPE}"]}
      ]
}
JSON
)" \
"https://app.datadoghq.com/api/v1/series?api_key=$DATADOG_API_KEY"

curl -X POST -H "Content-type: application/json" \
-d "$(cat <<JSON
{ "series" :
       [{"metric":"smoke_test.ss${METRIC_PREFIX}.loggregator.drain_msg_count",
        "points":[[${currenttime}, ${drain_count}]],
        "type":"gauge",
        "host":"${CF_SYSTEM_DOMAIN}",
        "tags":["drain_version:${DRAIN_VERSION}", "drain_type:${DRAIN_TYPE}"]}
      ]
  }
JSON
)" \
"https://app.datadoghq.com/api/v1/series?api_key=$DATADOG_API_KEY"

curl -X POST -H "Content-type: application/json" \
-d "$(cat <<JSON
{ "series" :
       [{"metric":"smoke_test.ss${METRIC_PREFIX}.loggregator.delay",
        "points":[[${currenttime}, ${DELAY_US}]],
        "type":"gauge",
        "host":"${CF_SYSTEM_DOMAIN}",
        "tags":["drain_version:${DRAIN_VERSION}", "drain_type:${DRAIN_TYPE}"]}
      ]
  }
JSON
)" \
"https://app.datadoghq.com/api/v1/series?api_key=$DATADOG_API_KEY"

curl -X POST -H "Content-type: application/json" \
-d "$(cat <<JSON
{
    "series" :
       [{"metric":"smoke_test.ss${METRIC_PREFIX}.loggregator.cycles",
       "points":[[${currenttime}, $(expr $CYCLES \* $NUM_APPS)]],
        "type":"gauge",
        "host":"${CF_SYSTEM_DOMAIN}",
        "tags":["drain_version:${DRAIN_VERSION}", "drain_type:${DRAIN_TYPE}"]}
      ]
  }
JSON
)" \
"https://app.datadoghq.com/api/v1/series?api_key=$DATADOG_API_KEY"

if [ "$msg_count" -eq 0 ]; then
    echo message count was zero, sad
    exit 1
fi