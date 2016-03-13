#!/bin/bash

MOSQ_VERSION="1.4.8"
MOSQ_URL="http://mosquitto.org/files/source/mosquitto-${MOSQ_VERSION}.tar.gz"

TMP_FILE="/tmp/mosquitto-${MOSQ_VERSION}.tar.gz"

# download & copy
curl -o $TMP_FILE $MOSQ_URL
tar zxf $TMP_FILE -C ${TMP_FILE%/*}
rsync -av --delete ${TMP_FILE%.tar.gz}/ ./mosquitto

# clean up
rm -rf ${TMP_FILE%-*}*
