#!/bin/bash

##
## WeatherFlow Collector - start-remote-import.sh
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
healthcheck=$WEATHERFLOW_COLLECTOR_HEALTHCHECK
host_hostname=$WEATHERFLOW_COLLECTOR_HOST_HOSTNAME
import_days=$WEATHERFLOW_COLLECTOR_IMPORT_DAYS
influxdb_bucket=$WEATHERFLOW_COLLECTOR_INFLUXDB_BUCKET
influxdb_org=$WEATHERFLOW_COLLECTOR_INFLUXDB_ORG
influxdb_token=$WEATHERFLOW_COLLECTOR_INFLUXDB_TOKEN
influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
weatherflow_token=$WEATHERFLOW_COLLECTOR_TOKEN
station_id=$WEATHERFLOW_COLLECTOR_STATION_ID

##
## Set Specific Variables
##

collector_type="remote-import"
function="import"

if [ "$debug" == "true" ]

then

echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} $(date) - Starting WeatherFlow Collector (start-remote-import.sh) - https://github.com/lux4rd0/weatherflow-collector

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
station_id=${station_id}
weatherflow_token=${weatherflow_token}
weatherflow_collector_version=${weatherflow_collector_version}"

fi

##
## Set InfluxDB Precision to seconds
##

#if [ -n "${influxdb_url}" ]; then influxdb_url="${influxdb_url}&precision=s"; fi

##
## Get Stations IDs from Token
##

url_stations="https://swd.weatherflow.com/swd/rest/stations?token=${weatherflow_token}"

#echo "url_stations=${url_stations}"

response_station=$(curl -s "${url_stations}")

number_of_devices=$(echo "${response_station}" |jq -r '.stations[] | select(.station_id == '"${station_id}"') | .devices[] | select(.device_type == "AR" or .device_type == "SK" or .device_type == "ST")' | jq -s '. | length')

#echo "${response_station}" | jq -r '.stations[] | select(.location_id == ${station_id}) | .devices'

echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} $(date) - number_of_devices: ${echo_bold}${number_of_devices}${echo_normal}"

number_of_devices_minus_one=$((number_of_devices-1))

> remote-import-url_"${station_id}"-station_list.txt
    
for device_number in $(seq 0 $number_of_devices_minus_one) ; do

#echo "device_number=${device_number}"

device_ar=($(echo "${response_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .devices[] | select(.device_type == "AR") |  .device_id | @sh') )
device_sk=($(echo "${response_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .devices[] | select(.device_type == "SK") |  .device_id | @sh') )
device_st=($(echo "${response_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .devices[] | select(.device_type == "ST") |  .device_id | @sh') )
        
if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} device_ar=${device_ar[*]} device_sk=${device_sk[*]} device_st=${device_st[*]}" ; fi

if [ -n "${device_ar[${device_number}]}" ]; then
#echo "station_number: ${station_number} station_id: ${station_id} device_number: ${device_number} device_ar: ${device_ar[${device_number}]}"
echo "${response_station}" |jq -r '.stations[] | select(.station_id == '"${station_id}"') | to_entries | .[4,5,6,7,8,9,12] | .key + "=" + "\"" + ( .value|tostring ) + "\""' > remote-import-device_id-"${device_ar[${device_number}]}"-lookup.txt
echo "elevation=\"$(echo "${response_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .station_meta.elevation')\"" >> remote-import-device_id-"${device_ar[${device_number}]}"-lookup.txt
echo "hub_sn=\"$(echo "${response_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .devices[] | select(.device_type == "HB") | .serial_number')\"" >> remote-import-device_id-"${device_ar[${device_number}]}"-lookup.txt
echo "https://swd.weatherflow.com/swd/rest/observations/device/${device_ar[${device_number}]}?token=${weatherflow_token}" >> remote-import-url_"${station_id}"-station_list.txt

fi

if [ -n "${device_sk[${device_number}]}" ]; then
#echo "station_number: ${station_number} station_id: ${station_id} device_number: ${device_number} device_sk: ${device_sk[${device_number}]}"
echo "${response_station}" |jq -r '.stations[] | select(.station_id == '"${station_id}"') | to_entries | .[4,5,6,7,8,9,12] | .key + "=" + "\"" + ( .value|tostring ) + "\""' > remote-import-device_id-"${device_sk[${device_number}]}"-lookup.txt
echo "elevation=\"$(echo "${response_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .station_meta.elevation')\"" >> remote-import-device_id-"${device_sk[${device_number}]}"-lookup.txt
echo "hub_sn=\"$(echo "${response_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .devices[] | select(.device_type == "HB") | .serial_number')\"" >> remote-import-device_id-"${device_sk[${device_number}]}"-lookup.txt
echo "https://swd.weatherflow.com/swd/rest/observations/device/${device_sk[${device_number}]}?token=${weatherflow_token}" >> remote-import-url_"${station_id}"-station_list.txt
fi

if [ -n "${device_st[${device_number}]}" ]; then
#echo "station_number: ${station_number} station_id: ${station_id} device_number: ${device_number} device_st: ${device_st[${device_number}]}"
echo "${response_station}" |jq -r '.stations[] | select(.station_id == '"${station_id}"') | to_entries | .[4,5,6,7,8,9,12] | .key + "=" + "\"" + ( .value|tostring ) + "\""' > remote-import-device_id-"${device_st[${device_number}]}"-lookup.txt
echo "elevation=\"$(echo "${response_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .station_meta.elevation')\"" >> remote-import-device_id-"${device_st[${device_number}]}"-lookup.txt
echo "hub_sn=\"$(echo "${response_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .devices[] | select(.device_type == "HB") | .serial_number')\"" >> remote-import-device_id-"${device_st[${device_number}]}"-lookup.txt
echo "https://swd.weatherflow.com/swd/rest/observations/device/${device_st[${device_number}]}?token=${weatherflow_token}" >> remote-import-url_"${station_id}"-station_list.txt

fi

done

##
## Init Progress Bar
##

init_progress_full $(((import_days + 1) * number_of_devices))

##
## Loop through the days for a full import
##

for days_loop in $(seq "$import_days" -1 0) ; do

##
## Reset full import timer if reset_progress_total_full.txt file exists
##

if [ -f "reset_progress_total_full.txt" ]; then progress_start_date_full=$(date +%s); progress_total_full="$(((days_loop + 1) * number_of_devices))"; progress_count_full=0; rm reset_progress_total_full.txt; fi

time_start=$(date --date="${days_loop} days ago 00:00" +%s)
time_end=$((time_start + 86399))

time_start_echo=$(date -d @"${time_start}")
time_end_echo=$(date -d @${time_end})

echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} $(date) - Day: ${echo_bold}${days_loop}${echo_normal} days ago"
echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} $(date) - time_start: ${time_start} - ${time_start_echo}"
echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} $(date) - time_end: ${time_end} - ${time_end_echo}"

remote_import_url="remote-import-url_${station_id}-station_list.txt"
while IFS=, read -r lookup_import_url lookup_station_id; do
if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} $(date) - lookup_import_url: ${lookup_import_url} lookup_station_id: ${lookup_station_id}"; fi

curl -w "\n" -X GET --header 'Accept: application/json' "${lookup_import_url}&time_start=${time_start}&time_end=${time_end}" | ./exec-remote-import.sh

#echo "${curl[@]}" -w "\n" -X GET --header 'Accept: application/json' "${lookup_import_url}&time_start=${time_start}&time_end=${time_end}"

##
## Increment Progress Bar
##

echo "${echo_bold}${echo_color_remote_import}${collector_type}:${echo_normal} Full Import Status Details"

inc_progress_full

echo "
"

done < "${remote_import_url}"

done