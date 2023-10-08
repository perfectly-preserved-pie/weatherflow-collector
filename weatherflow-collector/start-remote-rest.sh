#!/bin/bash

##
## WeatherFlow Collector - start-remote-rest.sh
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
debug_sleeping=$WEATHERFLOW_COLLECTOR_DEBUG_SLEEPING
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
rest_interval=$WEATHERFLOW_COLLECTOR_REST_INTERVAL
weatherflow_token=$WEATHERFLOW_COLLECTOR_TOKEN

##
## Set Specific Variables
##

collector_type="remote-rest"

if [ "$debug" == "true" ]

then

echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - Starting WeatherFlow Collector (start-remote-rest.sh) - https://github.com/lux4rd0/weatherflow-collector

Debug Environmental Variables

collector_type=${collector_type}
debug=${debug}
debug_curl=${debug_curl}
debug_sleeping=${debug_sleeping}
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
rest_interval=${rest_interval}
weatherflow_token=${weatherflow_token}
weatherflow_collector_version=${weatherflow_collector_version}"

fi

##
## Set InfluxDB Precision to seconds
##

#if [ -n "${influxdb_url}" ]; then influxdb_url="${influxdb_url}&precision=s"; fi

##
## Curl Command
##

if [ "$debug_curl" == "true" ]; then curl=(  ); else curl=( --silent --show-error --fail ); fi

##
## Check for required intervals
##

if [ -z "${rest_interval}" ] && [ "$collector_type" == "remote-rest" ]; then echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}WEATHERFLOW_COLLECTOR_REST_INTERVAL${echo_normal} environmental variable not set. Defaulting to ${echo_bold}60${echo_normal} seconds."; rest_interval="60"; export WEATHERFLOW_COLLECTOR_REST_INTERVAL="60"; fi

if [ -z "${host_hostname}" ]; then echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} $(date) - ${echo_bold}WEATHERFLOW_COLLECTOR_HOST_HOSTNAME${echo_normal} environmental variable not set. Defaulting to ${echo_bold}weatherflow-collector${echo_normal}."; host_hostname="weatherflow-collector"; export WEATHERFLOW_COLLECTOR_HOST_HOSTNAME="weatherflow-collector"; fi

##
## Send Startup Event Timestamp to InfluxDB
##

##
## Keep this before the Curl Command as it needs STDOUT
##

process_start

##
## Get Stations IDs from Token
##

url_stations="https://swd.weatherflow.com/swd/rest/stations?token=${weatherflow_token}"

#echo "url_stations=${url_stations}"

response_station=$(curl -s "${url_stations}")

number_of_stations=$(echo "${response_station}" |jq '.stations | length')
station_ids=($(echo "${response_station}" | jq -r '.stations[].station_id | @sh') )

#echo "Number of Stations: ${number_of_stations}"

number_of_stations_minus_one=$((number_of_stations-1))

> remote-rest-url_list.txt

for station_number in $(seq 0 $number_of_stations_minus_one) ; do

#echo "Station Number Loop: $station_number"
#echo "station_number: ${station_number} station_id: ${station_ids[${station_number}]}"

echo "https://swd.weatherflow.com/swd/rest/observations/station/${station_ids[${station_number}]}?token=${weatherflow_token}" >> remote-rest-url_list.txt

done

##
## Read URLs for Remote Rest
##

while ( true ); do
before=$(date +%s%N)

remote_rest_url="remote-rest-url_list.txt"

while IFS= read -r line

do

#echo "$line"

curl -s -w "\n" -X GET --header "Accept: application/json" "${line}" | ./exec-remote-rest.sh

#curl "${curl[@]}" -w "\n" -X GET --header "Accept: application/json" "${line}" | ./exec-remote-rest.sh

done < "$remote_rest_url"

after=$(date +%s%N)
delay=$(echo "scale=4;(${rest_interval}-($after-$before) / 1000000000)" | bc)
if [ "$debug_sleeping" == "true" ]; then echo "${echo_bold}${echo_color_remote_rest}${collector_type}:${echo_normal} Sleeping: ${delay} seconds"; fi
sleep "$delay"
done