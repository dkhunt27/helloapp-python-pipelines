#!/bin/bash -e

echo -e "\n*** apt-get update ***"
sudo apt-get update

echo -e "\n*** installing jq ***"
sudo apt-get install jq

echo -e "\n*** extracting manifest and params information ***"
MAN_FILE=IN/helloapp-man/manifestSteps/manifests.json
export PARAMS=$(jq -r '.[].images[].params' $MAN_FILE)
export MARATHON_APP_FILE=$(jq -r '.[].images[].params.MARATHON_APP_FILE' $MAN_FILE)
export ENVIRONMENT=$(jq -r '.[].images[].params.ENVIRONMENT' $MAN_FILE)
export MARATHON_HOST=$(jq -r '.[].images[].params.MARATHON_HOST' $MAN_FILE)
export MESOS_APP_NAME=$(jq -r '.[].images[].params.MESOS_APP_NAME' $MAN_FILE)
export IMAGE_NAME=$(jq -r '.[].images[].image' $MAN_FILE)
export IMAGE_TAG=$(jq -r '.[].images[].tag' $MAN_FILE)
export MEMORY=$(jq -r '.[].images[].dockerOptions.memory' $MAN_FILE)
export CPU_SHARES=$(jq -r '.[].images[].dockerOptions.cpuShares' $MAN_FILE)
export PORT_MAPPINGS=$(jq -r '.[].images[].dockerOptions.portMappings[]' $MAN_FILE)
export REPLICAS=$(jq -r '.[].replicas' $MAN_FILE)

echo -e "\n*** updating $MARATHON_APP_FILE ***"
cd IN/helloapp-scripts/gitRepo
python version.py
cat marathon.json

echo "\n*** deploying Application $MESOS_APP_NAME to $MARATHON_HOST ***"
APP_EXISTS=$(curl -s -o /dev/null -w "%{http_code}" ${MARATHON_HOST}/v2/apps/${MESOS_APP_NAME})

if [ "$APP_EXISTS" -eq "000" ]; then
  echo Failed to Connect to Marathon Host ${MARATHON_HOST}
  exit 1

elif [ "$APP_EXISTS" -eq "200" ]; then
  echo Updating Application ${MARATHON_HOST}/v2/apps/${MESOS_APP_NAME}
  curl -v -X PUT -H "Accept: application/json" -H "Content-Type: application/json" "${MARATHON_HOST}/v2/apps/${MESOS_APP_NAME}?force=true" -d @$MARATHON_APP_FILE

elif [ "$APP_EXISTS" -eq "404" ]; then
  echo Creating Application ${MARATHON_HOST}/v2/apps/${MESOS_APP_NAME}
  curl -v -X POST -H "Accept: application/json" -H "Content-Type: application/json" "${MARATHON_HOST}/v2/apps" -d @$MARATHON_APP_FILE

else
  echo Unknown HTTP Response while checking Marathon Application ${MARATHON_HOST}/v2/apps/${MESOS_APP_NAME}
  exit 1
fi

echo -e "\n*** processing complete - deploy-test.sh ***"
