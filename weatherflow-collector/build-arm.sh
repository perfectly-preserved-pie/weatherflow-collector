docker build  -f Dockerfile.arm -t lux4rd0/weatherflow-collector:latest-arm -t lux4rd0/weatherflow-collector:$1-arm -t docker01.tylephony.com:5000/lux4rd0/weatherflow-collector:latest-arm -t docker01.tylephony.com:5000/lux4rd0/weatherflow-collector:$1-arm .
#docker push docker01.tylephony.com:5000/lux4rd0/weatherflow-collector:latest-arm
docker push docker01.tylephony.com:5000/lux4rd0/weatherflow-collector:$1-arm
#docker push lux4rd0/weatherflow-collector:latest-arm
#docker push lux4rd0/weatherflow-collector:$1-arm
