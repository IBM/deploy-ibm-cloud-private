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
function init_mcm {
    export HOME=~
    cd $HOME
    export HELM_HOME=~/.helm

    systemArch=$(arch)
    if [ "${systemArch}" == "x86_64" ]; then systemArch='amd64'; fi
    
    helm init --client-only
    cloudctl login -a https://${HUB_CLUSTER_IP}:8443 --skip-ssl-validation \
        -u ${icp_admin_user} -p ${icp_admin_user_password} -n kube-system
    docker login ${cluster_name}.icp:8500 \
        -u ${icp_admin_user} -p ${icp_admin_user_password}
}

# Download and Load PPA archive
function load_ppa_archive {
    if [[ ! -f /tmp/mcm.tgz ]]; then
        if [[ "${user}" == "-" ]]; then user=""; fi
        if [[ "${password}" == "-" ]]; then password=""; fi
        wget -nv --continue -O /tmp/mcm.tgz "${location}" \
            ${user:+--user} ${user} ${password:+--password} ${password}
        if [[ $? -gt 0 ]]; then
            /bin/echo "Error downloading ${location}" >&2
            exit 1
        fi
    fi
    cd /tmp/
    tar -zxvf mcm.tgz
    mcm_file="/tmp/mcm-${ICP_VERSION}/mcm"
    if [ $ICP_VERSION == "3.1.1" ]; then
        mcm_file="${mcm_file}-${ICP_VERSION}-${systemArch}.tgz"
    else
        mcm_file="${mcm_file}-ppa-${ICP_VERSION}.tgz"
    fi
    cd -

    cloudctl catalog load-ppa-archive -a ${mcm_file} \
        --registry ${cluster_name}.icp:8500/kube-system
}

# Add helm chart
function add_ibm_chart_repos {

    helm repo add \
        local-charts https://${HUB_CLUSTER_IP}:8443/helm-repo/charts \
        --ca-file ~/.helm/ca.pem --cert-file ~/.helm/cert.pem \
        --key-file ~/.helm/key.pem
    if [[ $? -gt 0 ]]; then
        /bin/echo "Error adding local-charts, installing from tarball" >&2
    fi
    helm repo update
}


HUB_CLUSTER_IP=$1
ICP_VERSION=$2
cluster_name=mycluster
icp_admin_user=$3
icp_admin_user_password=$4
location=$5
user=$6
password=$7

/bin/echo
/bin/echo "Loading MCM.."

init_mcm
load_ppa_archive
add_ibm_chart_repos
/bin/echo "MCM Loading completed"
