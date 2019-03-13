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
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Licensed Materials - Property of IBM
#
# Copyright (C) 2019 IBM Corporation
#
# Yussuf Shaikh <yussuf@us.ibm.com> - Initial implementation.
#
################################################################

# Set HOME env var, populate systemArch, helm init and cloudctl login
function clean_cam {
    export HOME=~
    cd $HOME
    export HELM_HOME=~/.helm

    helm init --client-only
    cloudctl login -a https://${HUB_CLUSTER_IP}:8443 \
        --skip-ssl-validation -u ${icp_admin_user} -p ${icp_admin_user_password} -n services

    helm del --purge cam --timeout 1800 --tls
    kubectl delete pod --grace-period=0 --force --namespace services -l release=cam

    kubectl delete secret ${cam_docker_secret} -n services
}

# Install and configure exportfs; Create Persistent Volumes
function delete_persistent_volumes {
    pvs=( cam-mongo cam-logs cam-terraform cam-bpd-appdata )
    dir_names=( db logs terraform BPD_appdata )
    for ((i = 0; i < ${#pvs[@]}; ++i)); do
        item=${pvs[${i}]}
        kubectl delete pvc ${item}-pv
        kubectl delete pv ${item}-pv
    done
    sudo sed -i '/\/cam_export*/d' /etc/exports
}

# Delete a deployment ServiceID policies and API Key
function delete_deployment_key {
    export serviceIDName='service-deploy'
    export serviceApiKeyName='service-deploy-api-key'
    cloudctl iam service-id-delete ${serviceIDName} -f
}


HUB_CLUSTER_IP=$1
icp_admin_user=$2
icp_admin_user_password=$3
cam_docker_secret=$4

/bin/echo
/bin/echo "Cleaning CAM.."

clean_cam
delete_deployment_key
delete_persistent_volumes
/bin/echo "CAM cleaning completed"

