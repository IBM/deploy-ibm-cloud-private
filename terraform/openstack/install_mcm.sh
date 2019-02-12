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

# Set HOME env var, populate ARCH, helm init and cloudctl login
function init_mcm {
    export HOME=~
    cd $HOME
    export HELM_HOME=~/.helm

    machine=`uname -m`
    ARCH="amd64"
    if [ "$machine" == "ppc64le" ]; then
        ARCH="ppc64le"
    fi

    helm init --client-only
    cloudctl login -a https://${HUB_CLUSTER_IP}:8443 \
        --skip-ssl-validation -u admin -p admin -n kube-system
    docker login mycluster.icp:8500 -u admin -p admin
}

# Download and Load PPA archive
function load_ppa_archive {
    wget -nv --continue ${user:+--user} ${user} ${password:+--password} ${password} \
        -O /tmp/mcm.tgz "${location}"
    if [[ $? -gt 0 ]]; then
        /bin/echo "Error downloading ${location}" >&2
        exit 1
    fi

    cd /tmp/
    tar -zxvf mcm.tgz
    mcm_file="/tmp/mcm-${ICP_VERSION}/mcm-${ICP_VERSION}"
    mcm_file="${mcm_file}-${ARCH}.tgz"
    cd -

    ls /etc/docker/certs.d/
    docker login mycluster.icp:8500 -u admin -p admin
    ls /etc/docker/certs.d/
    ping -c 1 mycluster.icp
    cloudctl catalog load-ppa-archive -a ${mcm_file} \
        --registry mycluster.icp:8500/kube-system
    ls /etc/docker/certs.d/
}

# Create MCM namespace and Tiller secret
function create_namespace_n_secret {
    export MCM_NAMESPACE=mcm
    export KLUSTERLET_TILLER_SECRET=secret
    kubectl create secret tls ${KLUSTERLET_TILLER_SECRET} \
        --cert ~/.helm/cert.pem --key ~/.helm/key.pem -n kube-system
    kubectl create namespace ${MCM_NAMESPACE}
}

# Add helm chart
function add_ibm_chart_repos {
    export CLUSTER_NAME=mycluster
    export CLUSTER_NAMESPACE=kube-system

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
    export HUB_CLUSTER_NAME=mycluster
    export HUB_CLUSTER_USER=mycluster-user
    export HUB_CLUSTER_URL=`kubectl config view -o \
        jsonpath="{.clusters[?(@.name==\"${HUB_CLUSTER_NAME}\")].cluster.server}"`
    export HUB_CLUSTER_TOKEN=`kubectl config view -o \
        jsonpath="{.users[?(@.name==\"${HUB_CLUSTER_USER}\")].user.token}"`

    export MCM_HELM_RELEASE_NAME=myhelmmcm
    helm install --name=${MCM_HELM_RELEASE_NAME} \
        --namespace kube-system \
        --set compliance.mcmNamespace=${MCM_NAMESPACE} \
        --set klusterlet.enabled=true \
        --set topology.enabled=true \
        --set klusterlet.clusterName=${CLUSTER_NAME} \
        --set klusterlet.clusterNamespace=${CLUSTER_NAMESPACE} \
        --set klusterlet.tillersecret=${KLUSTERLET_TILLER_SECRET} \
        --set klusterlet.apiserverConfig.server=${HUB_CLUSTER_URL} \
        --set klusterlet.apiserverConfig.token=${HUB_CLUSTER_TOKEN} \
        ${CHARTNAME} --tls \
        --ca-file ~/.helm/ca.pem --cert-file ~/.helm/cert.pem --key-file ~/.helm/key.pem
    if [[ $? -gt 0 ]]; then
        /bin/echo "MCM installation failed" >&2
        exit 1
    fi
}

# Install CLI
function install_mcm_cli {
    docker run -e LICENSE=accept -v /usr/local/bin:/data \
        mycluster.icp:8500/kube-system/mcmctl:${ICP_VERSION} \
        cp mcmctl-linux-${ARCH} /data/mcmctl
}


HUB_CLUSTER_IP=$1
ICP_VERSION=$2

/bin/echo
/bin/echo "Installing MCM.."
location=$3
user=$4
password=$5

init_mcm
load_ppa_archive
create_namespace_n_secret
add_ibm_chart_repos
install_mcm
install_mcm_cli
/bin/echo "MCM installation completed"

