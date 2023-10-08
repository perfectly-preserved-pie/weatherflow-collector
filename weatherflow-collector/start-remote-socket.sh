#!/bin/bash

##
## WeatherFlow Collector - start-remote-socket.sh
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

collector_type="remote-socket"

if [ "$debug" == "true" ]

then

echo "${echo_bold}${echo_color_remote_socket}${collector_type}:${echo_normal} $(date) - Starting WeatherFlow Collector (start-remote-socket.sh) - https://github.com/lux4rd0/weatherflow-collector

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
weatherflow_token=${weatherflow_token}
weatherflow_collector_version=${weatherflow_collector_version}"

fi

##
## Set InfluxDB Precision to seconds
##

#if [ -n "${influxdb_url}" ]; then influxdb_url="${influxdb_url}&precision=s"; fi

##
## Send Startup Event Timestamp to InfluxDB
##

process_start

##
## Curl Command
##

if [ "$debug_curl" == "true" ]; then curl=(  ); else curl=( --silent --output /dev/null --show-error --fail ); fi

##
## Random ID
##

random_id=$(od -A n -t d -N 1 /dev/urandom |tr -d ' ')

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

socket_json="\n"

for station_number in $(seq 0 $number_of_stations_minus_one) ; do

#echo "Station Number Loop: $station_number"

#echo "station_number: ${station_number} station_id: ${station_ids[${station_number}]}"

number_of_devices=$(echo "${response_station}" |jq '.stations['"${station_number}"'].devices | length')

#echo "number_of_devices: ${number_of_devices}"

number_of_devices_minus_one=$((number_of_devices-1))

json_variable=${station_ids[${station_number}]}
socket_json="${socket_json}{\"type\":\"listen_start_events\",\"station_id\":\"$json_variable\",\"id\":\"weatherflow-collector-listen_start_events_${random_id}\"}\n"

echo "${response_station}" | jq -r '.stations['"${station_number}"'] | {"location_id", "station_id", "name", "public_name", "latitude", "longitude", "timezone"}' | jq -r '. | to_entries | .[] | .key + "=" + "\"" + ( .value|tostring ) + "\""' > remote-socket-station_id-"${station_ids[${station_number}]}"-lookup.txt
echo "elevation=\"$(echo "${response_station}" |jq -r '.stations['"${station_number}"'].station_meta.elevation')\"" >> remote-socket-station_id-"${station_ids[${station_number}]}"-lookup.txt

#echo "${socket_json}"
    
for device_number in $(seq 0 $number_of_devices_minus_one) ; do

#echo "device_number: ${device_number}"

device_ar=($(echo "${response_station}" | jq -r '.stations['"${station_number}"'].devices[] | select(.device_type == "AR") | .device_id | @sh') )
device_sk=($(echo "${response_station}" | jq -r '.stations['"${station_number}"'].devices[] | select(.device_type == "SK") | .device_id | @sh') )
device_st=($(echo "${response_station}" | jq -r '.stations['"${station_number}"'].devices[] | select(.device_type == "ST") | .device_id | @sh') )

if [ -n "${device_ar[${device_number}]}" ]; then
#echo "station_number: ${station_number} station_id: ${station_ids[${station_number}]} device_number: ${device_number} device_ar: ${device_ar[${device_number}]}"
json_variable=${device_ar[${device_number}]}
socket_json="${socket_json}{\"type\":\"listen_start\",\"device_id\":\"$json_variable\",\"id\":\"weatherflow-collector-listen_start_${random_id}\"}\n"
socket_json="${socket_json}{\"type\":\"listen_rapid_start\",\"device_id\":\"$json_variable\",\"id\":\"weatherflow-collector-listen_rapid_start_${random_id}\"}\n"

echo "${response_station}" |jq -r '.stations['"${station_number}"'] | to_entries | .[4,5,6,7,8,9,12] | .key + "=" + "\"" + ( .value|tostring ) + "\""' > remote-socket-device_id-"${device_ar[${device_number}]}"-lookup.txt
echo "elevation=\"$(echo "${response_station}" |jq -r '.stations['"${station_number}"'].station_meta.elevation')\"" >> remote-socket-device_id-"${device_ar[${device_number}]}"-lookup.txt

#echo "${socket_json}"

fi

if [ -n "${device_sk[${device_number}]}" ]; then
#echo "station_number: ${station_number} station_id: ${station_ids[${station_number}]} device_number: ${device_number} device_sk: ${device_sk[${device_number}]}"
json_variable=${device_sk[${device_number}]}
socket_json="${socket_json}{\"type\":\"listen_start\",\"device_id\":\"$json_variable\",\"id\":\"weatherflow-collector-start_${random_id}\"}\n"

echo "${response_station}" |jq -r '.stations['"${station_number}"'] | to_entries | .[4,5,6,7,8,9,12] | .key + "=" + "\"" + ( .value|tostring ) + "\""' > remote-socket-device_id-"${device_sk[${device_number}]}"-lookup.txt
echo "elevation=\"$(echo "${response_station}" |jq -r '.stations['"${station_number}"'].station_meta.elevation')\"" >> remote-socket-device_id-"${device_sk[${device_number}]}"-lookup.txt

#echo "${socket_json}"

fi

if [ -n "${device_st[${device_number}]}" ]; then
#echo "station_number: ${station_number} station_id: ${station_ids[${station_number}]} device_number: ${device_number} device_st: ${device_st[${device_number}]}"
json_variable=${device_st[${device_number}]}
socket_json="${socket_json}{\"type\":\"listen_start\",\"device_id\":\"$json_variable\",\"id\":\"weatherflow-collector-start_${random_id}\"}\n"
socket_json="${socket_json}{\"type\":\"listen_rapid_start\",\"device_id\":\"$json_variable\",\"id\":\"weatherflow-collector-listen_rapid_start_${random_id}\"}\n"

echo "${response_station}" |jq -r '.stations['"${station_number}"'] | to_entries | .[4,5,6,7,8,9,12] | .key + "=" + "\"" + ( .value|tostring ) + "\""' > remote-socket-device_id-"${device_st[${device_number}]}"-lookup.txt
echo "elevation=\"$(echo "${response_station}" |jq -r '.stations['"${station_number}"'].station_meta.elevation')\"" >> remote-socket-device_id-"${device_st[${device_number}]}"-lookup.txt

#echo "${socket_json}"

fi

done

done

#echo "${socket_json}"

echo -e "${socket_json}" | ./websocat -n "wss://ws.weatherflow.com/swd/data?token=${weatherflow_token}" | ./exec-remote-socket.sh
