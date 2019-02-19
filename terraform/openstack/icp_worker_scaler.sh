#!/bin/bash

################################################################
# Module to deploy IBM Cloud Private
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# Copyright IBM Corp. 2017.
#
################################################################

# Root directory of ICP installation
ICP_ROOT_DIR="/opt/ibm-cloud-private-${2}"
IPS=${3}

ICP_DOCKER_IMAGE=`sudo /usr/bin/docker ps -a | /bin/grep -i 'inception' | head -1 | /usr/bin/awk '{print $2}'`
if [[ $? -gt 0 ]]; then
    /bin/echo "Error using docker, skipping." >&2
    exit 1
fi
cd "$ICP_ROOT_DIR/cluster"

if [[ ${1} == a* ]]; then
    sudo /usr/bin/docker run -e LICENSE=accept --net=host \
        -v "$(pwd)":/installer/cluster \
        $ICP_DOCKER_IMAGE worker -l $IPS | \
        sudo /usr/bin/tee -a add_remove_worker.log
elif [[ ${1} == r* ]]; then
    sudo /usr/bin/docker run -e LICENSE=accept --net=host \
        -v "$(pwd)":/installer/cluster \
        $ICP_DOCKER_IMAGE uninstall -l $IPS | \
        sudo /usr/bin/tee -a add_remove_worker.log
else
   echo "None of the condition met"
fi

exit 0
