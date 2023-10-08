#!/bin/bash

##
## WeatherFlow Collector - weatherflow-collector_details.sh
##

weatherflow_collector_version="4.0.0"
#grafana_loki_binary_path="./promtail-linux-amd64"
grafana_loki_binary_path="/usr/bin/promtail"
debug_sleeping=$WEATHERFLOW_COLLECTOR_DEBUG_SLEEPING
collector_key=$(echo ${WEATHERFLOW_COLLECTOR_TOKEN} | awk -F"-" '{print $1}')

##
## Echo Details
##

echo_bold=$(tput -T xterm bold)
echo_blink=$(tput -T xterm blink)
echo_black=$(tput -T xterm setaf 0)
echo_blue=$(tput -T xterm setaf 4)
echo_dim=$(tput -T xterm dim)

echo_color_health_check=$(echo -e "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m")
echo_color_host_performance=$(echo -e "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m")
echo_color_local_udp=$(echo -e "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m")
echo_color_remote_forecast=$(echo -e "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m")
echo_color_remote_rest=$(echo -e "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m")
echo_color_remote_socket=$(echo -e "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m")
echo_color_start=$(echo -e "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m")
echo_color_remote_import=$(echo -e "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m")
echo_color_random=$(echo -e "\e[3$(( $RANDOM * 6 / 32767 + 1 ))m")

echo_normal=$(tput -T xterm sgr0)

##
## Functions
##

##
## ┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐    ┌┐┌┌─┐┌┬┐┌─┐┌─┐
## ├┤ └─┐│  ├─┤├─┘├┤     │││├─┤│││├┤ └─┐
## └─┘└─┘└─┘┴ ┴┴  └─┘────┘└┘┴ ┴┴ ┴└─┘└─┘
##

function escape_names () {

##
## Change Variable Name for Name - Station Name
##

#echo "Coming In"
#echo "name:${name} station_name=${station_name}"

if [ -n "${name}" ]; then station_name="${name}"; fi

#echo "Going Out"
#echo "name:${name} station_name=${station_name}"

##
## Escape Names
##

##
## Spaces
##

public_name_escaped="${public_name// /\\ }"
station_name_escaped="${station_name// /\\ }"

##
## Commas
##

public_name_escaped="${public_name_escaped//,/\\,}"
station_name_escaped="${station_name_escaped//,/\\,}"

##
## Equal Signs
##

public_name_escaped="${public_name_escaped//=/\\=}"
station_name_escaped="${station_name_escaped//=/\\=}"

}

##
## ╔═╗┬─┐┌─┐┌─┐┬─┐┌─┐┌─┐┌─┐╔╗ ┌─┐┬─┐
## ╠═╝├┬┘│ ││ ┬├┬┘├┤ └─┐└─┐╠╩╗├─┤├┬┘
## ╩  ┴└─└─┘└─┘┴└─└─┘└─┘└─┘╚═╝┴ ┴┴└─
##
## ProgressBar - https://github.com/fearside/ProgressBar/
##

function ProgressBar () {
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")
printf "\r${echo_bold}Progress${echo_normal} : ${echo_bold}[${echo_normal}${_fill// /${echo_red}${echo_bold}▒${echo_normal}}${_empty// /░}${echo_bold}]${echo_normal} ${echo_bold}${_progress}%%${echo_normal}"
}

##
## ┬ ┬┌─┐┌─┐┬ ┌┬┐┬ ┬    ┌─┐┬ ┬┌─┐┌─┐┬┌─
## ├─┤├┤ ├─┤│  │ ├─┤    │  ├─┤├┤ │  ├┴┐
## ┴ ┴└─┘┴ ┴┴─┘┴ ┴ ┴────└─┘┴ ┴└─┘└─┘┴ ┴
##

function health_check () {

if [ "$healthcheck" == "true" ]; then health_check_file="health-check-${collector_type}.txt"; touch ${health_check_file}; fi

}

##
## ┌─┐┬─┐┌─┐┌─┐┌─┐┌─┐┌─┐    ┌─┐┌┬┐┌─┐┬─┐┌┬┐
## ├─┘├┬┘│ ││  ├┤ └─┐└─┐    └─┐ │ ├─┤├┬┘ │ 
## ┴  ┴└─└─┘└─┘└─┘└─┘└─┘────└─┘ ┴ ┴ ┴┴└─ ┴ 
##

##
## Send Startup Event Timestamp to InfluxDB
##

function process_start () {

if [ "$curl_debug" == "true" ]; then curl=(  ); else curl=( --silent --output /dev/null --show-error --fail ); fi

current_time=$(date +%s)

#echo "${bold}${collector_type}:${normal} time_epoch: ${current_time}"


if [ -n "$influxdb_url" ]; then

curl_message="weatherflow_system_events,collector_key=${collector_key},collector_type=${collector_type},event="process_start",host_hostname=${host_hostname},source=${function} time_epoch=${current_time}000";

curl_send_message

fi

}

##
## ┬┌┐┌┬┌┬┐   ┌─┐┬─┐┌─┐┌─┐┬─┐┌─┐┌─┐┌─┐
## │││││ │    ├─┘├┬┘│ ││ ┬├┬┘├┤ └─┐└─┐
## ┴┘└┘┴ ┴────┴  ┴└─└─┘└─┘┴└─└─┘└─┘└─┘
##

function init_progress() {
	progress_start_date=$(date +%s)
	progress_total="$1"
	progress_count=0
}

##
## ProgressBar2 - http://geoffles.github.io/development/2019/01/31/progress-in-bash.html
##

function inc_progress() {
	progress_count=$((progress_count+1))
	progress_percent=$((100 * progress_count / progress_total))
	progress_barlength=$((progress_percent / 4))
	progress_time=$(( $(date +%s) - progress_start_date ))
	progress_remaining=$(( ((100*progress_time/progress_count) * (progress_total-progress_count))/100 ))

	printf "\r%d%% (%d of %d)  ${echo_bold}[${echo_normal}" "$progress_percent" "$progress_count" "$progress_total" 
	for i in {1..25}
	do
		if [ "$i" -gt "$progress_barlength" ]
		then printf "%s" "${echo_dim}░${echo_normal}"
		else

if [ "$i" -ge "1" ] && [ "$i" -le "3" ]; then printf "\033[01;38;5;52m${echo_bold}▒${echo_normal}"; fi
if [ "$i" -ge "4" ] && [ "$i" -le "6" ]; then printf "\033[01;38;5;124m${echo_bold}▒${echo_normal}"; fi
if [ "$i" -ge "7" ] && [ "$i" -le "9" ]; then printf "\033[01;38;5;196m${echo_bold}▒${echo_normal}"; fi
if [ "$i" -ge "10" ] && [ "$i" -le "12" ]; then printf "\033[01;38;5;202m${echo_bold}▒${echo_normal}"; fi
if [ "$i" -ge "13" ] && [ "$i" -le "15" ]; then printf "\033[01;38;5;214m${echo_bold}▒${echo_normal}"; fi
if [ "$i" -ge "16" ] && [ "$i" -le "18" ]; then printf "\033[01;38;5;220m${echo_bold}▒${echo_normal}"; fi
if [ "$i" -ge "19" ] && [ "$i" -le "21" ]; then printf "\033[01;38;5;228m${echo_bold}▒${echo_normal}"; fi
if [ "$i" -ge "22" ] && [ "$i" -le "25" ]; then printf "\033[01;38;5;231m${echo_bold}▒${echo_normal}"; fi

		fi
	done

    printf "${echo_bold}]${echo_normal} - Remaining: "; show_progress_time $progress_remaining
}

##
## ┬┌┐┌┬┌┬┐   ┌─┐┬─┐┌─┐┌─┐┬─┐┌─┐┌─┐┌─┐    ┌─┐┬ ┬┬  ┬  
## │││││ │    ├─┘├┬┘│ ││ ┬├┬┘├┤ └─┐└─┐    ├┤ │ ││  │  
## ┴┘└┘┴ ┴────┴  ┴└─└─┘└─┘┴└─└─┘└─┘└─┘────└  └─┘┴─┘┴─┘
##
## ProgressBar2 - http://geoffles.github.io/development/2019/01/31/progress-in-bash.html
##

function init_progress_full() {
	progress_start_date_full=$(date +%s)
	progress_total_full="$1"
	progress_count_full=0
}

##
## ┬┌┐┌┌─┐    ┌─┐┬─┐┌─┐┌─┐┬─┐┌─┐┌─┐┌─┐    ┌─┐┬ ┬┬  ┬  
## │││││      ├─┘├┬┘│ ││ ┬├┬┘├┤ └─┐└─┐    ├┤ │ ││  │  
## ┴┘└┘└─┘────┴  ┴└─└─┘└─┘┴└─└─┘└─┘└─┘────└  └─┘┴─┘┴─┘
##

function inc_progress_full() {
	progress_count_full=$((progress_count_full+1))
	progress_percent_full=$((100 * progress_count_full / progress_total_full))
	progress_barlength_full=$((progress_percent_full / 4))
	progress_time_full=$(( $(date +%s) - progress_start_date_full ))
	progress_remaining_full=$(( ((100*progress_time_full/progress_count_full) * (progress_total_full-progress_count_full))/100 ))

	printf "\r%d%% (%d of %d)  ${echo_bold}[${echo_normal}" "$progress_percent_full" "$progress_count_full" "$progress_total_full" 
	for i in {1..25}
	do
		if [ "$i" -gt "$progress_barlength_full" ]
		then printf "%s" "░"
		else printf "%s" "${echo_blue}${echo_bold}▒${echo_normal}"
		fi
	done

    printf "${echo_bold}]${echo_normal} - Remaining: "; show_progress_time $progress_remaining_full
}

##
## ┌─┐┬ ┬┌─┐┬ ┬    ┌─┐┬─┐┌─┐┌─┐┬─┐┌─┐┌─┐┌─┐   ┌┬┐┬┌┬┐┌─┐
## └─┐├─┤│ ││││    ├─┘├┬┘│ ││ ┬├┬┘├┤ └─┐└─┐    │ ││││├┤ 
## └─┘┴ ┴└─┘└┴┘────┴  ┴└─└─┘└─┘┴└─└─┘└─┘└─┘────┴ ┴┴ ┴└─┘
##

function show_progress_time () {
    num=$1
    min=0
    hour=0
    day=0
    if((num>59));then
        ((sec=num%60))
        ((num=num/60))
        if((num>59));then
            ((min=num%60))
            ((num=num/60))
            if((num>23));then
                ((hour=num%24))
                ((day=num/24))
            else
                ((hour=num))
            fi
        else
            ((min=num))
        fi
    else
        ((sec=num))
    fi
    echo -n "${echo_bold}$hour"h "$min"m "$sec"s"${echo_normal}"
}


##
## ┌─┐┬ ┬┬─┐┬    ┌─┐┌─┐┌┐┌┌┬┐  ┌┬┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐
## │  │ │├┬┘│    └─┐├┤ │││ ││  │││├┤ └─┐└─┐├─┤│ ┬├┤ 
## └─┘└─┘┴└─┴─┘  └─┘└─┘┘└┘─┴┘  ┴ ┴└─┘└─┘└─┘┴ ┴└─┘└─┘
##

function curl_send_message() {

#echo "airSensors,sensor_id=TLM0201 temperature=73.97038159354763,humidity=35.23103248356096,co=0.48445310567793615 1630525358 
#  airSensors,sensor_id=TLM0202 temperature=75.30007505999716,humidity=35.651929918691714,co=0.5141876544505826 1630525358" | gzip > air-sensors.gzip

#curl --request POST \
#"http://localhost:8086/api/v2/write?org=YOUR_ORG&bucket=YOUR_BUCKET&precision=ns" \
#  --header "Authorization: Token YOUR_API_TOKEN" \
#  --header "Content-Encoding: gzip" \
#  --header "Content-Type: text/plain; charset=utf-8" \
#  --header "Accept: application/json" \
#  --data-binary @air-sensors.gzip


if [ "$debug_curl" == "true" ]; then curl=(  ); else curl=( --silent --output /dev/null --show-error --fail ); fi

curl "${curl[@]}" --request POST \
"${influxdb_url}/api/v2/write?org=${influxdb_org}&bucket=${influxdb_bucket}" \
  --header "Authorization: Token ${influxdb_token}" \
  --header "Content-Type: text/plain; charset=utf-8" \
  --header "Accept: application/json" \
  --data-binary "
    ${curl_message}
    "

}
