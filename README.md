## About The Project

**weatherflow-collector** is a set of scripts that provide different ways of collecting and publishing data from the [WeatherFlow Tempest](https://weatherflow.com/tempest-weather-system/) weather system and visualize that data with Grafana dashboards. This collector is part of my [WeatherFlow Dashboards AIO](https://github.com/lux4rd0/weatherflow-dashboards-aio) (All In One) project.

There are several different collector types available once you deploy your  WeatherFlow device:

 - Local: UDP Collector
 - Remote: WeatherFlow API

## Getting Started

The project builds a pre-configured Docker container that takes different configurations based on how you want to collect and where you want to store the data.

## Prerequisites

- [Docker](https://docs.docker.com/install)
- [Docker Compose](https://docs.docker.com/compose/install)
- [InfluxDB 1.8](https://docs.influxdata.com/influxdb/v1.8/) or [Grafana Loki 2.2](https://grafana.com/oss/loki/)

## Notice

Like all projects - weatherflow-collector is always in a flux state based on trying out new things and seeing what works and what doesn't work. It started as a fun exercise to visualize "what's possible," and I'm experimenting with different collectors and backends. Please expect breaking changes along the way.

## Using

There's an example [docker-compose.yml](https://github.com/lux4rd0/weatherflow-collector/blob/main/docker-compose-sample.yml) file that you should update the environmental flags for your specific collection and databases.

Use the following [Docker container](https://hub.docker.com/r/lux4rd0/weatherflow-collector):

    lux4rd0/weatherflow-collector:2.4.0
    lux4rd0/weatherflow-collector:latest

Environmental flags:

```WEATHERFLOW_COLLECTOR_BACKEND_TYPE```

- influxdb (supports local-udp, remote-rest (forecasts), and remote-socket (observations)
- loki (supports local-udp and remote-socket (observations)

```WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE```

- [remote-socket](https://weatherflow.github.io/Tempest/api/ws.html)
- [local-udp](https://weatherflow.github.io/Tempest/api/udp.html)
- [remote-rest](https://weatherflow.github.io/Tempest/api/swagger/#/observations/)
- [remote-forecast](https://weatherflow.github.io/Tempest/api/swagger/#/forecast/)

```WEATHERFLOW_COLLECTOR_DEBUG```

- true
- false

```WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD```

The password for your InfluxDB

```WEATHERFLOW_COLLECTOR_INFLUXDB_URL```

The URL connection string for your InfluxDB. For example: http://influxdb:8086/write?db=weatherflow

```WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME```

The username of your InfluxDB

```WEATHERFLOW_COLLECTOR_REMOTE_COLLECTOR_DEVICE_ID```

The Device ID of your Tempest

```WEATHERFLOW_COLLECTOR_REMOTE_COLLECTOR_STATION_ID```

The Station ID of your Tempest

```WEATHERFLOW_COLLECTOR_REMOTE_COLLECTOR_TOKEN```

The WeatherFlow Personal Access Token.

```WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL```

The URL connection string for your Grafana Loki endpoint. For example: http://loki:3100/loki/api/v1/push

```WEATHERFLOW_COLLECTOR_REMOTE_FORECAST_INTERVAL```

Number in seconds that you want to pull the forecast data. (Defaults to 60 seconds)

```WEATHERFLOW_COLLECTOR_REMOTE_REST_INTERVAL```

Number in seconds that you want to pull observability data. (Defaults to 60 seconds)

If you want to just run a single instance, for example - the forecast collector, a docker command would look like:

    docker run -d \
      --name=weatherflow-collector-remote-rest-influxdb \
      --restart always \
      -e WEATHERFLOW_COLLECTOR_BACKEND_TYPE=influxdb \
      -e WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=remote-rest \
      -e WEATHERFLOW_COLLECTOR_DEBUG=false \
      -e WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD=PASSWORD \
      -e WEATHERFLOW_COLLECTOR_INFLUXDB_URL=http://influxdb:8086/write?db=weatherflow \
      -e WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME=influxdb \
      -e WEATHERFLOW_COLLECTOR_REMOTE_COLLECTOR_DEVICE_ID=DEVICE_ID \
      -e WEATHERFLOW_COLLECTOR_REMOTE_COLLECTOR_STATION_ID=STATION_ID \
      -e WEATHERFLOW_COLLECTOR_REMOTE_COLLECTOR_TOKEN=TOKEN \
      -e WEATHERFLOW_COLLECTOR_REMOTE_FORECAST_INTERVAL=60 \
      lux4rd0/weatherflow-collector:latest

## Obtaining Your Tempest API Details

 You can obtain this by signing in to the Tempest Web App at tempestwx.com, then go to Settings -> Data Authorizations -> Create Token.

### Get Station Meta Data

Retrieve a list of your stations along with all connected devices.

https://swd.weatherflow.com/swd/rest/stations?token=[your_access_token]

A quick jq command to find your station_id and device_id would look like:

#### STATION_ID

    curl https://swd.weatherflow.com/swd/rest/stations?token=[your_access_token] | jq .stations[0].station_id

#### DEVICE_ID

    curl https://swd.weatherflow.com/swd/rest/stations?token=[your_access_token] | jq .stations[0].devices[1].device_id

If you have multiple Tempest devices connected to multiple hubs, use .stations[1], etc., for each station under your account.

## Collector Details

#### remote-socket

This setting grabs all of the metrics from your Tempest and all of the [derived metrics](https://weatherflow.github.io/Tempest/api/derived-metric-formulas.html), accomplished with WeatherFlow backend AI systems. The metrics don't have the same metrics resolution as the local-udp collector but supports lightning suppression and sea level pressure adjustments. It also provides for additional events such as online and offline status. This setting works with both Grafana Loki and InfluxDB 1.8.

#### remote-rest

This setting is similiar to the remote-socket for obtaining Weatherflow observations but only pulls data once a minute from a REST call. A few additional metrics are available on this collector such as sea level pressure. Still working out which metrics make sense and the right kind of polling mechanism to put in place - so I'm trying out both!

#### local-udp

This setting provides a listener on UDP port 50222 for messages coming from your Tempest hub. It provides all of the raw observation details and details on the Hub and Tempest, such as RSSI Wifi details, uptime, sensor details, and device battery voltage. The observation metrics have a slightly higher resolution of data than what the REST/Socket API calls provide. However, it does not give any of the [derived metrics](https://weatherflow.github.io/Tempest/api/derived-metric-formulas.html) available with the REST/Socket API calls. This setting works with both Grafana Loki and InfluxDB 1.8.

#### remote-forecast

This setting populates the WeatherFlow Forecast dashboards. It makes a Web services call to pull the daily and hourly forecasts for your location and stores them in InfluxDB. It runs the forecasting process on startup and every 60 minutes after the start of the container. This setting works only works with InfluxDB 1.8.

## Grafana Dashboards

Collecting data is only half the fun. Now it's time to provision some Grafana Dashboards to visualize all of our great WeatherFlow data. You'll find a [folder of dashboards](https://github.com/lux4rd0/weatherflow-collector/tree/main/dashboards) with collectors and backends split out.

The "**WeatherFlow - Overview**" dashboard is the starting point with a listing of Current observations along with historical details..

Other dashboards can be viewed by selecting the "WeatherFlow" drop-down from the top righthand side of the dashboards:

<center><img src="https://github.com/lux4rd0/weatherflow-dashboards-aio/raw/main/images/weatherflow-dashboards.jpg"></center>

There are different dashboards for **local-udp** and **remote-rest**.

**WeatherFlow - Today So Far**

<center><img src="./images/weatherflow-today_so_far_remote-socket-influxdb.jpg"></center>

Temperature, Relative Humidity, Station Pressure, Accumulated Rain, Solar Radiation, Illuminance, UV, Lightening Strike, and Wind Speed since midnight. Rapid Wind Direction and Wind Speed over the last 60 seconds is also updated every 5 seconds (by default).

There are different dashboards for **local-udp** and **remote-rest** collectors.

**WeatherFlow - Forecast**

<center><img src="./images/weatherflow-forecast-influxdb.jpg"></center>

The Forecast dashboard provides both a daily and hourly forecast in table format with charts below them. The default time range includes the current day plus nine coming days. The interval drop-down at the top defaults to 12 hours to provide for highs and lows forecasts.

This dashboard uses the **remote-rest** collector and **InfluxDB** backend.

**WeatherFlow - Forecast vs. Observed**

A comparisons of data that was forecasted overlayed with historic observations.

This dashboard uses the **remote-rest** collectors with the **InfluxDB** backend.

**WeatherFlow - Device Details**

<center><img src="https://github.com/lux4rd0/weatherflow-dashboards-aio/raw/main/images/weatherflow-weatherflow-device_details.jpg"></center>

Provides the current status for both the Tempest and WeatherFlow hub such as Uptime, Radio Status, RSSI, Reboot Count, I2C Bus Count Error, Radio Version, Network ID, Firmware Version, and Voltage.

<center><img src="https://github.com/lux4rd0/weatherflow-dashboards-aio/raw/main/images/weatherflow-weatherflow-device_details-device_status.jpg"></center>

Another panel provides an overview of Sensor Status measurements - either "Sensors OK" or if there were any failures.

<center><img src="https://github.com/lux4rd0/weatherflow-dashboards-aio/raw/main/images/weatherflow-weatherflow-device_details-sensor_status.jpg"></center>

There's also RSSI and Battery Voltage over time defaulted to the last seven days.

<center><img src="https://github.com/lux4rd0/weatherflow-dashboards-aio/raw/main/images/weatherflow-weatherflow-device_details-battery.jpg"></center>
<center><img src="https://github.com/lux4rd0/weatherflow-dashboards-aio/raw/main/images/weatherflow-weatherflow-device_details-rssi.jpg"></center>

This dashboard uses the **local-udp** collector.

## Multiple Devices ##

The data collector supports mulitple devices but these dashboards have been simplified to work with only a single device for simplicity. If you'd like a set of dashboards for mulitple devices, please let me know.

### Time Zone Variable

There's also a tz variable coded to a specific location to help build some of the 12/24 hour time breaks. It's set to "America/Chicago" - you will need to modify this to your specific time zone. I'm looking to define this based on your device settings in a future release.

## Roadmap

Dashboards that use the Loki backend will be added back into the project shortly.

See the open issues for a list of proposed features (and known issues).

## Contact

Dave Schmid - [@lux4rd0](https://twitter.com/lux4rd0) - dave@pulpfree.org
Project Link: https://github.com/lux4rd0/weatherflow-collector

## Acknowledgements

- Grafana Labs - https://grafana.com/
- Grafana - https://grafana.com/oss/grafana/
- Grafana Dashboard Community - https://grafana.com/grafana/dashboards
