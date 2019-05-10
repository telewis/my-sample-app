#!/bin/bash

#
# Start the app
#
nohup ./goapp &

#
# Verify the app is running
#
pid=$(ps -ef | grep goapp | grep -v grep | awk '{print $2}')
while [ -z "${pid}" ]
do
  sleep 5
  pid=$(ps -ef | grep goapp | grep -v grep | awk '{print $2}')
done

#
# Set the expected values
#
listenPort=8080
imageName=MyImageName
imageTag=MyImageTag
environment=MyEnvironment
secret=MySecret
dnsString=*.k8s.toddelewis.net
host=$(uname -n)
#os=$(uname -s)
os="darwin"
pingOutput=Todds-MacBook-Pro.local-pong

#
# Call the app
#
output=$(curl -s http://localhost:${listenPort})
##echo "${output}"

#
# Get the output
#
outImage=$(echo ${output} | awk -F: '{print $1}' | sed -e 's/ //g')
outImageTag=$(echo ${output} | awk -F: '{print $2}' | sed -e 's/ //g')
outEnvironment=$(echo ${output} | awk -F: '{print $4}' | sed -e 's/ //g')
outSecret=$(echo ${output} | awk -F: '{print $6}' | sed -e 's/ //g')
outOS=$(echo ${output} | awk -F: '{print $8}' | sed -e 's/ //g')
outHost=$(echo ${output} | awk -F: '{print $10}' | sed -e 's/ //g')

#
# Compare the output with the expected value
#
if [ "${imageName}" != "${outImage}" ]; then
    echo "Image Name Mismatch: ${imageName} != ${outImage}"
    exit 1
fi

if [ "${imageTag}" != "${outImageTag}" ]; then
    echo "Image Tag Mismatch: ${imageTag} != ${outTag}"
    exit 1
fi

if [ "${environment}" != "${outEnvironment}" ]; then
    echo "Environment Mismatch: ${environment} != ${outEnvironment}"
    exit 1
fi

if [ "${secret}" != "${outSecret}" ]; then
    echo "Secret Mismatch: ${secret} != ${outSecret}"
    exit 1
fi

if [ "${os}" != "${outOS}" ]; then
    echo "OS Mismatch: ${os} != ${outOS}"
    exit 1
fi

if [ "${host}" != "${outHost}" ]; then
    echo "Host Mismatch: ${host} != ${outHost}"
    exit 1
fi

outPingOutput=$(curl -s http://localhost:${listenPort}/ping)
if [ "${pingOutput}" != "${outPingOutput}" ]; then
    echo "Ping Mismatch: ${pingOutput} != ${outPingOutput}"
    exit 1
fi

pid=$(ps -ef | grep goapp | grep -v grep | awk '{print $2}')
kill ${pid}

echo "Tests Successful"