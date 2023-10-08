#!/bin/bash

##
## WeatherFlow Collector - start-emote-forecast.sh
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
forecast_interval=$WEATHERFLOW_COLLECTOR_FORECAST_INTERVAL
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
threads=$WEATHERFLOW_COLLECTOR_THREADS
weatherflow_token=$WEATHERFLOW_COLLECTOR_TOKEN

##
## Set Specific Variables
##

collector_type="remote-forecast"

if [ "$debug" == "true" ]

then

echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} $(date) - Starting WeatherFlow Collector (start-remote-forecast.sh) - https://github.com/lux4rd0/weatherflow-collector

Debug Environmental Variables

backend_type=${backend_type}
collector_type=${collector_type}
debug=${debug}
debug_curl=${debug_curl}
debug_sleeping=${debug_sleeping}
device_id=${device_id}
elevation=${elevation}
forecast_interval=${forecast_interval}
function=${function}
healthcheck=${healthcheck}
host_hostname=${host_hostname}
hub_sn=${hub_sn}
import_days=${import_days}
influxdb_bucket=${influxdb_bucket}
influxdb_org=${influxdb_org}
influxdb_token=${influxdb_token}
influxdb_url=${influxdb_url}
latitude=${latitude}
logcli_host_url=${logcli_host_url}
loki_client_url=${loki_client_url}
longitude=${longitude}
public_name=${public_name}
rest_interval=${rest_interval}
station_id=${station_id}
station_name=${station_name}
threads=${threads}
timezone=${timezone}
weatherflow_token=${weatherflow_token}"

fi

##
## Set InfluxDB Precision to seconds
##

#if [ -n "${influxdb_url}" ]; then influxdb_url="${influxdb_url}&precision=s"; fi

##
## Check for required intervals
##

if [ -z "${forecast_interval}" ] && [ "$collector_type" == "remote-forecast" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} ${echo_bold}WEATHERFLOW_COLLECTOR_FORECAST_INTERVAL${echo_normal} environmental variable not set. Defaulting to ${echo_bold}60${echo_normal} seconds."; forecast_interval="60"; fi

##
## Send Startup Event Timestamp to InfluxDB
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

> remote-forecast-url_station_list.txt

for station_number in $(seq 0 $number_of_stations_minus_one); do

echo "https://swd.weatherflow.com/swd/rest/better_forecast?station_id=${station_ids[${station_number}]}&token=${weatherflow_token},${station_ids[${station_number}]}" >> remote-forecast-url_station_list.txt

echo "hub_sn=\"$(echo "${response_station}" | jq -r '.stations['"${station_number}"'].devices[] | select(.device_type == "HB") | .serial_number')\"" > remote-forecast-station_id-"${station_ids[${station_number}]}"-lookup.txt
echo "device_id=\"$(echo "${response_station}" | jq -r '.stations['"${station_number}"'].devices[] | select(.device_type == "HB") | .device_id')\"" >> remote-forecast-station_id-"${station_ids[${station_number}]}"-lookup.txt


echo "${response_station}" | jq -r '.stations['"${station_number}"'] | to_entries | .[4,5,6,7,8,9,12] | .key + "=" + "\"" + ( .value|tostring ) + "\""' >> remote-forecast-station_id-"${station_ids[${station_number}]}"-lookup.txt

echo "elevation=\"$(echo "${response_station}" |jq -r '.stations['"${station_number}"'].station_meta.elevation')\"" >> remote-forecast-station_id-"${station_ids[${station_number}]}"-lookup.txt

done

startup_check=0

quarter_hour_offset=$(shuf -i 0-14 -n 1)

if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} $(date) - quarter_hour_offset: ${quarter_hour_offset}"; fi

echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} $(date) - Running at $quarter_hour_offset, $((quarter_hour_offset + 15)), $((quarter_hour_offset + 30)), and $((quarter_hour_offset + 45)) minutes after the hour"

##
## Start Forecast Continuous Loop
##

while ( true ); do

##
## Read URLs for Remote Forecast
##

#echo "${station_json[0]}"

before=$(date +%s%N)

##
## Run the hourly forecasts every 15 minutes at a random quarter hour offset
## This help (kind of) stagger usage if there are more than one Forecast
## container running
##

if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} $(date) - quarter_hour_offset: ${quarter_hour_offset}"; fi

hourly_time_build_check_minute=$(date +"%-M")

if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} $(date) - hourly_time_build_check_minute: ${hourly_time_build_check_minute}"; fi

if [[ "$hourly_time_build_check_minute" == "$quarter_hour_offset" ]] || [[ "$hourly_time_build_check_minute" == "$((quarter_hour_offset + 15))" ]] || [[ "$hourly_time_build_check_minute" == "$((quarter_hour_offset + 30))" ]] || [[ "$hourly_time_build_check_minute" == "$((quarter_hour_offset + 45))" ]]

then

hourly_time_build_check_flag="true"

if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} $(date) - Running Hourly Forecast Interval Build - ${hourly_time_build_check_minute} Minute"; fi

else

hourly_time_build_check_flag="false"

if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} $(date) - Skipping Hourly Forecast Interval Build - ${hourly_time_build_check_minute} Minute"; fi

fi

##
## Run on startup
##

if [ "$startup_check" == "0" ]; then hourly_time_build_check_flag="true"; echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} $(date) - Running Hourly Forecast Interval Build - First Time Startup"; fi

remote_forecast_url="remote-forecast-url_station_list.txt"

while IFS=, read -r lookup_forecast_url lookup_station_id; do

if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} $(date) - lookup_forecast_url: ${lookup_forecast_url} lookup_station_id: ${lookup_station_id}"; fi

curl -s -w "\n" -X GET --header "Accept: application/json" "${lookup_forecast_url}" | WEATHERFLOW_COLLECTOR_HOURLY_FORECAST_RUN=${hourly_time_build_check_flag} WEATHERFLOW_COLLECTOR_STATION_ID="${lookup_station_id}" ./exec-remote-forecast.sh

done < ${remote_forecast_url}

after=$(date +%s%N)
delay=$(echo "scale=4;(${forecast_interval}-($after-$before) / 1000000000)" | bc)

if [ "$debug_sleeping" == "true" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} $(date) - Sleeping: ${delay} seconds"; fi

((startup_check=startup_check+1))
if [ "$debug" == "true" ]; then echo "${echo_bold}${echo_color_remote_forecast}${collector_type}:${echo_normal} $(date) - Loop: ${startup_check}"; fi
sleep "$delay"
done