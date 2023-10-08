#!/bin/bash

##
## WeatherFlow Collector - start-remote-export.sh
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
export_days=$WEATHERFLOW_COLLECTOR_EXPORT_DAYS
influxdb_password=$WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD
influxdb_url=$WEATHERFLOW_COLLECTOR_INFLUXDB_URL
influxdb_username=$WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME
weatherflow_token=$WEATHERFLOW_COLLECTOR_TOKEN
station_id=$WEATHERFLOW_COLLECTOR_STATION_ID

##
## Set Specific Variables
##

collector_type="remote-export"
function="export"

if [ "$debug" == "true" ]

then

echo "${echo_bold}${echo_color_remote_export}${collector_type}:${echo_normal} $(date) - Starting WeatherFlow Collector (start-remote-export.sh) - https://github.com/lux4rd0/weatherflow-collector

Debug Environmental Variables

collector_type=${collector_type}
debug=${debug}
debug_curl=${debug_curl}
function=${function}
healthcheck=${healthcheck}
host_hostname=${host_hostname}
export_days=${export_days}
influxdb_password=${influxdb_password}
influxdb_url=${influxdb_url}
influxdb_username=${influxdb_username}
logcli_host_url=${logcli_host_url}
loki_client_url=${loki_client_url}
station_id=${station_id}
weatherflow_token=${weatherflow_token}
weatherflow_collector_version=${weatherflow_collector_version}"

fi

##
## Get Stations IDs from Token
##

url_stations="https://swd.weatherflow.com/swd/rest/stations?token=${weatherflow_token}"

#echo "url_stations=${url_stations}"

response_station=$(curl -s "${url_stations}")

number_of_devices=$(echo "${response_station}" |jq -r '.stations[] | select(.station_id == '"${station_id}"') | .devices[] | select(.device_type == "AR" or .device_type == "SK" or .device_type == "ST")' | jq -s '. | length')

#echo "${response_station}" | jq -r '.stations[] | select(.location_id == ${station_id}) | .devices'

echo "${echo_bold}${echo_color_remote_export}${collector_type}:${echo_normal} $(date) - Number of Devices: ${echo_bold}${number_of_devices}${echo_normal}, Station ID: ${station_id}"


number_of_devices_minus_one=$((number_of_devices-1))

> remote-export-url_"${station_id}"-station_list.txt
    
for device_number in $(seq 0 $number_of_devices_minus_one) ; do

#echo "device_number=${device_number}"

device_ar=($(echo "${response_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .devices[] | select(.device_type == "AR") |  .device_id | @sh') )
device_sk=($(echo "${response_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .devices[] | select(.device_type == "SK") |  .device_id | @sh') )
device_st=($(echo "${response_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .devices[] | select(.device_type == "ST") |  .device_id | @sh') )
        
if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_export}${collector_type}:${echo_normal} device_ar=${device_ar[*]} device_sk=${device_sk[*]} device_st=${device_st[*]}" ; fi

if [ -n "${device_ar[${device_number}]}" ]; then
#echo "station_number: ${station_number} station_id: ${station_id} device_number: ${device_number} device_ar: ${device_ar[${device_number}]}"
#echo "${response_station}" |jq -r '.stations[] | select(.station_id == '"${station_id}"') | to_entries | .[0,1,2,3,4,5,6] | .key + "=" + "\"" + ( .value|tostring ) + "\""' > remote-export-device_id-"${device_ar[${device_number}]}"-lookup.txt
#echo "elevation=\"$(echo "${response_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .station_meta.elevation')\"" >> remote-export-device_id-"${device_ar[${device_number}]}"-lookup.txt
#echo "hub_sn=\"$(echo "${response_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .devices[] | select(.device_type == "HB") | .serial_number')\"" >> remote-export-device_id-"${device_ar[${device_number}]}"-lookup.txt
echo "https://swd.weatherflow.com/swd/rest/observations/device/${device_ar[${device_number}]}?token=${weatherflow_token}&format=csv,${device_ar[${device_number}]}" >> remote-export-url_"${station_id}"-station_list.txt

fi

if [ -n "${device_sk[${device_number}]}" ]; then
#echo "station_number: ${station_number} station_id: ${station_id} device_number: ${device_number} device_sk: ${device_sk[${device_number}]}"
#echo "${response_station}" |jq -r '.stations[] | select(.station_id == '"${station_id}"') | to_entries | .[0,1,2,3,4,5,6] | .key + "=" + "\"" + ( .value|tostring ) + "\""' > remote-export-device_id-"${device_sk[${device_number}]}"-lookup.txt
#echo "elevation=\"$(echo "${response_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .station_meta.elevation')\"" >> remote-export-device_id-"${device_sk[${device_number}]}"-lookup.txt
#echo "hub_sn=\"$(echo "${response_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .devices[] | select(.device_type == "HB") | .serial_number')\"" >> remote-export-device_id-"${device_sk[${device_number}]}"-lookup.txt
echo "https://swd.weatherflow.com/swd/rest/observations/device/${device_sk[${device_number}]}?token=${weatherflow_token}&format=csv,${device_sk[${device_number}]}" >> remote-export-url_"${station_id}"-station_list.txt
fi

if [ -n "${device_st[${device_number}]}" ]; then
#echo "station_number: ${station_number} station_id: ${station_id} device_number: ${device_number} device_st: ${device_st[${device_number}]}"
#echo "${response_station}" |jq -r '.stations[] | select(.station_id == '"${station_id}"') | to_entries | .[0,1,2,3,4,5,6] | .key + "=" + "\"" + ( .value|tostring ) + "\""' > remote-export-device_id-"${device_st[${device_number}]}"-lookup.txt
#echo "elevation=\"$(echo "${response_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .station_meta.elevation')\"" >> remote-export-device_id-"${device_st[${device_number}]}"-lookup.txt
#echo "hub_sn=\"$(echo "${response_station}" | jq -r '.stations[] | select(.station_id == '"${station_id}"') | .devices[] | select(.device_type == "HB") | .serial_number')\"" >> remote-export-device_id-"${device_st[${device_number}]}"-lookup.txt
echo "https://swd.weatherflow.com/swd/rest/observations/device/${device_st[${device_number}]}?token=${weatherflow_token}&format=csv,${device_st[${device_number}]}" >> remote-export-url_"${station_id}"-station_list.txt

fi

done

##
## Init Progress Bar
##

init_progress_full $(((export_days + 1) * number_of_devices))

##
## Init Export
##

export_number=0

##
## Loop through the days for a full export
##

for days_loop in $(seq "$export_days" -1 0) ; do

##
## Reset full export timer if reset_progress_total_full.txt file exists
##

if [ -f "reset_progress_total_full.txt" ]; then progress_start_date_full=$(date +%s); progress_total_full="$(((days_loop + 1) * number_of_devices))"; progress_count_full=0; rm reset_progress_total_full.txt; fi

time_start=$(date --date="${days_loop} days ago 00:00" +%s)
time_end=$((time_start + 86399))

time_start_echo=$(date -d @"${time_start}")
time_end_echo=$(date -d @${time_end})

#echo "${echo_bold}${echo_color_remote_export}${collector_type}:${echo_normal} $(date) - Day: ${echo_bold}${days_loop}${echo_normal} days ago"
#echo "${echo_bold}${echo_color_remote_export}${collector_type}:${echo_normal} $(date) - time_start: ${time_start} - ${time_start_echo}"
#echo "${echo_bold}${echo_color_remote_export}${collector_type}:${echo_normal} $(date) - time_end: ${time_end} - ${time_end_echo}"

remote_export_url="remote-export-url_${station_id}-station_list.txt"
while IFS=, read -r lookup_export_url lookup_device_id; do
if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_export}${collector_type}:${echo_normal} $(date) - lookup_export_url: ${lookup_export_url} lookup_device_id: ${lookup_device_id}"; fi

# curl "${curl[@]}" -w "\n" -X GET --header 'Accept: application/json' "${lookup_export_url}&time_start=${time_start}&time_end=${time_end}" | ./exec-remote-export.sh

##
## Capture csv data
##

csv_data=$(curl "${curl[@]}" -w "\n" -X GET --header 'Accept: application/json' "${lookup_export_url}&time_start=${time_start}&time_end=${time_end}")
#csv_head=$(echo "${csv_data}" | head -1)
csv_tail=$(echo "${csv_data}" | tail -n +2)

#echo "${echo_bold}${echo_color_remote_export}${collector_type}:${echo_normal} $(date) - lookup_export_url: ${lookup_export_url} lookup_device_id: ${lookup_device_id}"

#echo "days_loop=${days_loop}"
if [ $export_number = "0" ]; then 

echo "${csv_data}" > export/weatherflow-collector_export-station_"${station_id}-device_${lookup_device_id}".csv

else

if [ -n "${csv_tail}" ]; then echo "${csv_tail}" >> export/weatherflow-collector_export-station_"${station_id}-device_${lookup_device_id}".csv

else

#echo "${echo_bold}${echo_color_remote_export}${collector_type}:${echo_normal} $(date) - No data for this date."

progress_start_date_full=$(date +%s); progress_total_full="$(((days_loop + 1) * number_of_devices))"; progress_count_full=0

fi
fi


#curl "${curl[@]}" -w "\n" -X GET --header 'Accept: application/json' "${lookup_export_url}&time_start=${time_start}&time_end=${time_end}&format=csv"

#echo "${curl[@]}" -w "\n" -X GET --header 'Accept: application/json' "${lookup_export_url}&time_start=${time_start}&time_end=${time_end}"

##
## Increment Progress Bar
##

#echo "${echo_bold}${echo_color_remote_export}${collector_type}:${echo_normal} Full Export Status Details"

inc_progress_full



((export_number=export_number+1))

done < "${remote_export_url}"



done
