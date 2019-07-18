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
# Yussuf Shaikh <yussuf@us.ibm.com> - Initial implementation for ICP 3.2.0 and above.
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
    helm repo add mgmt-charts \
        https://${HUB_CLUSTER_IP}:8443/mgmt-repo/charts \
        --ca-file ~/.helm/ca.pem \
        --cert-file ~/.helm/cert.pem \
        --key-file ~/.helm/key.pem
}

# Install MultiCloud Manager
function install_mcm {
    CHARTNAME=mgmt-charts/ibm-mcm-prod
    export MCM_HELM_RELEASE_NAME=multicluster-hub
    helm upgrade --install ${MCM_HELM_RELEASE_NAME} \
        --timeout 1800 --namespace kube-system \
        --set compliance.mcmNamespace=${mcm_namespace} \
        --set tillerIntegration.user=${icp_admin_user} \
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
}

# Install MCM Klusterlet
function install_mcm_klusterlet {
    kubectl create namespace ${mcm_namespace}
    export KUBECONFIG=/tmp/kubeconfig
    kubectl config set-cluster ${cluster_name} --server=${HUB_CLUSTER_URL} --insecure-skip-tls-verify=true
    kubectl config set-context ${cluster_name}-context --cluster=${cluster_name}
    kubectl config set-credentials ${icp_admin_user} --token=${HUB_CLUSTER_TOKEN}
    kubectl config set-context ${cluster_name}-context --user=${icp_admin_user} --namespace=default
    kubectl config use-context ${cluster_name}-context
    unset KUBECONFIG

    kubectl create secret generic klusterlet-bootstrap -n kube-system --from-file=/tmp/kubeconfig

    CHARTNAME=mgmt-charts/ibm-klusterlet
    export MCMK_HELM_RELEASE_NAME=multicluster-klusterlet
    helm del --purge ${MCMK_HELM_RELEASE_NAME} --tls
    helm upgrade --install ${MCMK_HELM_RELEASE_NAME} \
        --timeout 1800 --namespace kube-system \
        --set klusterlet.enabled=true \
        --set global.clusterName=${klusterlet_name} \
        --set global.clusterNamespace=${mcm_namespace} \
        --set tillerIntegration.user=${icp_admin_user} \
        --set tillerIntegration.autoGenTillerSecret=true \
        ${CHARTNAME} --tls \
        --ca-file ~/.helm/ca.pem \
        --cert-file ~/.helm/cert.pem \
        --key-file ~/.helm/key.pem
    if [[ $? -gt 0 ]]; then
        /bin/echo "MCM Klusterlet installation failed" >&2
        exit 1
    fi
}

HUB_CLUSTER_IP=$1
icp_admin_user=$2
icp_admin_user_password=$3
KLUSTERLET_ONLY=$4
cluster_name=mycluster
klusterlet_name=$5
mcm_namespace=$6
HUB_CLUSTER_URL=$7
HUB_CLUSTER_TOKEN=$8

/bin/echo
/bin/echo "Installing MCM.."
init_mcm
if [ "${KLUSTERLET_ONLY}" == "false" ]; then
    install_mcm
fi
install_mcm_klusterlet
/bin/echo "MCM installation completed"
