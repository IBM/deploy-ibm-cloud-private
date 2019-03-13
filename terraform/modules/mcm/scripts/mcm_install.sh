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
    cloudctl login -a https://${HUB_CLUSTER_IP}:8443 \
        --skip-ssl-validation -u ${icp_admin_user} -p ${icp_admin_user_password} -n kube-system
    docker login ${cluster_name}.icp:8500 -u ${icp_admin_user} -p ${icp_admin_user_password}
}

# Download and Load PPA archive
function load_ppa_archive {
    if [[ ! -f /tmp/mcm.tgz ]]; then
        if [[ "${user}" == "-" ]]; then user=""; fi
        if [[ "${password}" == "-" ]]; then password=""; fi
        wget -nv --continue ${user:+--user} ${user} ${password:+--password} ${password} \
            -O /tmp/mcm.tgz "${location}"
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

# Create MCM namespace and Tiller secret
function create_namespace_n_secret {
    
    if ! kubectl get secret ${mcm_secret} &> /dev/null; then
        kubectl create secret tls ${mcm_secret} \
            --cert ~/.helm/cert.pem --key ~/.helm/key.pem -n kube-system
    else
        echo "Secret ${mcm_secret_name} already exists"
    fi
    kubectl create namespace ${mcm_namespace}
}

# Add helm chart
function add_ibm_chart_repos {

    helm repo add local-charts https://${HUB_CLUSTER_IP}:8443/helm-repo/charts \
        --ca-file ~/.helm/ca.pem --cert-file ~/.helm/cert.pem --key-file ~/.helm/key.pem
    if [[ $? -gt 0 ]]; then
        /bin/echo "Error adding local-charts, installing from tarball" >&2
        CHARTNAME=$mcm_file
    else
        CHARTNAME=local-charts/ibm-mcm-prod
    fi
    helm repo update
}

# Install MultiCloud Manager
function install_mcm {
    export MCM_HELM_RELEASE_NAME=mcm-release
    helm upgrade --install ${MCM_HELM_RELEASE_NAME} \
        --timeout 1800 --namespace kube-system \
        --set compliance.mcmNamespace=${mcm_namespace} \
        --set topology.enabled=true \
        ${CHARTNAME} --tls \
        --ca-file ~/.helm/ca.pem --cert-file ~/.helm/cert.pem --key-file ~/.helm/key.pem
    if [[ $? -gt 0 ]]; then
        /bin/echo "MCM installation failed" >&2
        exit 1
    fi
}

# Install MCM Klusterlet
function install_mcm_klusterlet {
    export HUB_CLUSTER_URL=`kubectl config view -o \
        jsonpath="{.clusters[?(@.name==\"${cluster_name}\")].cluster.server}"`
    export HUB_CLUSTER_TOKEN=`kubectl config view -o \
        jsonpath="{.users[?(@.name==\"${cluster_name}-user\")].user.token}"`
    CHARTNAME=local-charts/ibm-mcmk-prod

    export MCMK_HELM_RELEASE_NAME=mcmk-release
    helm upgrade --install ${MCMK_HELM_RELEASE_NAME} \
        --timeout 1800 --namespace kube-system \
        --set klusterlet.enabled=true \
        --set klusterlet.clusterName=${cluster_name} \
        --set klusterlet.clusterNamespace=${mcm_cluster_namespace} \
        --set klusterlet.tillersecret=${mcm_secret} \
        --set klusterlet.apiserverConfig.server=${HUB_CLUSTER_URL} \
        --set klusterlet.apiserverConfig.token=${HUB_CLUSTER_TOKEN} \
        ${CHARTNAME} --tls \
        --ca-file ~/.helm/ca.pem --cert-file ~/.helm/cert.pem --key-file ~/.helm/key.pem
    if [[ $? -gt 0 ]]; then
        /bin/echo "MCM Klusterlet installation failed" >&2
        exit 1
    fi
}

# Install CLI
function install_mcm_cli {
    docker run -e LICENSE=accept -v /usr/local/bin:/data \
        ${cluster_name}.icp:8500/kube-system/mcmctl:${ICP_VERSION} \
        cp mcmctl-linux-${systemArch} /data/mcmctl
}


/bin/echo "/tmp/install_mcm.sh " $*

HUB_CLUSTER_IP=$1
ICP_VERSION=$2
cluster_name=$3
icp_admin_user=$4
icp_admin_user_password=$5
mcm_secret=$6
mcm_namespace=$7
mcm_cluster_namespace=$8

/bin/echo
/bin/echo "Installing MCM.."
location=$9
user=$10
password=$11

init_mcm
load_ppa_archive
create_namespace_n_secret
add_ibm_chart_repos
install_mcm
install_mcm_klusterlet
install_mcm_cli
/bin/echo "MCM installation completed"
