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
# Yussuf Shaikh <yussuf@us.ibm.com> - Seperated loading charts and install.
# Yussuf Shaikh <yussuf@us.ibm.com> - Allow Klusterlet only install.
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
}

# Install MultiCloud Manager
function install_mcm {
    CHARTNAME=local-charts/ibm-mcm-prod
    kubectl create namespace ${mcm_namespace}

    export MCM_HELM_RELEASE_NAME=mcm-release
    helm upgrade --install ${MCM_HELM_RELEASE_NAME} \
        --timeout 1800 --namespace kube-system \
        --set compliance.mcmNamespace=${mcm_namespace} \
        --set topology.enabled=true \
        ${CHARTNAME} --tls \
        --ca-file ~/.helm/ca.pem \
        --cert-file ~/.helm/cert.pem \
        --key-file ~/.helm/key.pem
    if [[ $? -gt 0 ]]; then
        /bin/echo "MCM installation failed" >&2
        exit 1
    fi

    HUB_CLUSTER_URL=`kubectl config view -o \
        jsonpath="{.clusters[?(@.name==\"${cluster_name}\")].cluster.server}"`
    HUB_CLUSTER_TOKEN=`kubectl config view -o \
        jsonpath="{.users[?(@.name==\"${cluster_name}-user\")].user.token}"`
    mcm_namespace=${mcm_namespace}k
}

# Install MCM Klusterlet
function install_mcm_klusterlet {
    CHARTNAME=local-charts/ibm-mcmk-prod
    kubectl create namespace ${mcm_namespace}

    export MCMK_HELM_RELEASE_NAME=mcmk-release
    helm upgrade --install ${MCMK_HELM_RELEASE_NAME} \
        --timeout 1800 --namespace kube-system \
        --set klusterlet.enabled=true \
        --set klusterlet.clusterName=${klusterlet_name} \
        --set klusterlet.clusterNamespace=${mcm_namespace} \
        --set klusterlet.autoGenTillerSecret=true \
        --set klusterlet.apiserverConfig.server=${HUB_CLUSTER_URL} \
        --set klusterlet.apiserverConfig.token=${HUB_CLUSTER_TOKEN} \
        ${CHARTNAME} --tls \
        --ca-file ~/.helm/ca.pem \
        --cert-file ~/.helm/cert.pem \
        --key-file ~/.helm/key.pem
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


HUB_CLUSTER_IP=$1
ICP_VERSION=$2
icp_admin_user=$3
icp_admin_user_password=$4
KLUSTERLET_ONLY=$5
cluster_name=mycluster
klusterlet_name=$6
mcm_namespace=$7
HUB_CLUSTER_URL=$8
HUB_CLUSTER_TOKEN=$9

/bin/echo
/bin/echo "Installing MCM.."

init_mcm
if [ "${KLUSTERLET_ONLY}" == "false" ]; then
    install_mcm
fi
install_mcm_klusterlet
install_mcm_cli
/bin/echo "MCM installation completed"
