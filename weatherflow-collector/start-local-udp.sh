#!/bin/bash

##
## WeatherFlow Collector - start-local-udp.sh
##

##
## WeatherFlow-Collector Details
##

source weatherflow-collector_details.sh

##
## Set Variables from Environmental Variables
##

debug=$WEATHERFLOW_COLLECTOR_DEBUG
debug_curl=$WEATHERFLOW_COLLECTOR_DEBUG_CURL
function=$WEATHERFLOW_COLLECTOR_FUNCTION
healthcheck=$WEATHERFLOW_COLLECTOR_HEALTHCHECK
host_hostname=$WEATHERFLOW_COLLECTOR_HOST_HOSTNAME
import_days=$WEATHERFLOW_COLLECTOR_IMPORT_DAYS
influxdb_bucket=$WEATHERFLOW_COLLECTOR_INFLUXDB_BUCKET
influxdb_org=$WEATHERFLOW_COLLECTOR_INFLUXDB_ORG
influxdb_token=$WEATHERFLOW_COLLECTOR_INFLUXDB_TOKEN
influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
logcli_host_url=$WEATHERFLOW_COLLECTOR_LOGCLI_URL
loki_client_url=$WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL
weatherflow_token=$WEATHERFLOW_COLLECTOR_TOKEN

##
## Set Specific Variables
##

collector_type="local-udp"

if [ "$debug" == "true" ]

then

echo "${echo_bold}${collector_type}:${normal} $(date) - Starting WeatherFlow Collector (start-local-udp.sh) - https://github.com/lux4rd0/weatherflow-collector

Debug Environmental Variables

collector_type=${collector_type}
debug=${debug}
debug_curl=${debug_curl}
function=${function}
healthcheck=${healthcheck}
host_hostname=${host_hostname}
import_days=${import_days}
influxdb_bucket=${influxdb_bucket}
influxdb_org=${influxdb_org}
influxdb_token=${influxdb_token}
influxdb_url=${influxdb_url}
logcli_host_url=${logcli_host_url}
loki_client_url=${loki_client_url}
threads=${threads}
weatherflow_token=${weatherflow_token}
weatherflow_collector_version=${weatherflow_collector_version}"

fi

##
## Send Startup Event Timestamp to InfluxDB
##

process_start

##
## Get Stations IDs from Token
##

url_stations="https://swd.weatherflow.com/swd/rest/stations?token=${weatherflow_token}"

response_station=$(curl -s "${url_stations}")

#echo "${response_station}"

number_of_stations=$(echo "${response_station}" |jq '.stations | length')
station_sns=($(echo "${response_station}" | jq -r '.stations[].devices[] | select(.device_type == "HB") | .serial_number') )

#echo "Number of Stations: ${number_of_stations}"

number_of_stations_minus_one=$((number_of_stations-1))

for station_number in $(seq 0 $number_of_stations_minus_one) ; do

echo "${response_station}" | jq -r '.stations['"${station_number}"'] | {"location_id", "station_id", "name", "public_name", "latitude", "longitude", "timezone"}' | jq -r '. | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""' > local-udp-hub_sn-"${station_sns[${station_number}]}"-lookup.txt
echo "elevation=\"$(echo "${response_station}" |jq -r '.stations['"${station_number}"'].station_meta.elevation')\"" >> local-udp-hub_sn-"${station_sns[${station_number}]}"-lookup.txt
    
done
#echo "${socket_json}"

#/usr/bin/stdbuf -oL /usr/bin/python weatherflow-listener.py
/usr/bin/stdbuf -oL /usr/bin/python weatherflow-listener.py | ./exec-local-udp.sh
