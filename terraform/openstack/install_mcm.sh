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

ICP_VERSION=$1
IP=$5

/bin/echo "Installing MCM.."

export HOME=~
# Download and Load PPA archive
cd $HOME
location=$2
user=$3
password=$4
wget -nv --continue ${user:+--user} ${user} ${password:+--password} ${password} \
     -O /tmp/mcm.tgz "${location}"
 
if [[ $? -gt 0 ]]; then
    /bin/echo "Error downloading ${image_location}" >&2
    exit 1
fi

cd /tmp/
tar -zxvf mcm.tgz
mcm_file="/tmp/mcm-${ICP_VERSION}/mcm-${ICP_VERSION}"
platform=`uname -p`
ARCH="amd64"
if [ "$platform" == "ppc64le" ]
then
    ARCH="ppc64le"
fi
mcm_file="${mcm_file}-${ARCH}.tgz"

CHARTNAME=$mcm_file
cd -

export HUB_CLUSTER_IP=$IP
export HELM_HOME=~/.helm
helm init --client-only

cloudctl login -a https://${HUB_CLUSTER_IP}:8443 \
    --skip-ssl-validation -u admin -p admin -n kube-system

export HUB_CLUSTER_NAME=mycluster
export HUB_CLUSTER_USER=mycluster-user
export HUB_CLUSTER_URL=`kubectl config view -o \
    jsonpath="{.clusters[?(@.name==\"${HUB_CLUSTER_NAME}\")].cluster.server}"`
export HUB_CLUSTER_TOKEN=`kubectl config view -o \
    jsonpath="{.users[?(@.name==\"${HUB_CLUSTER_USER}\")].user.token}"`

docker login mycluster.icp:8500 -u admin -p admin
cloudctl catalog load-ppa-archive -a ${mcm_file} \
    --registry mycluster.icp:8500/kube-system



# Create MCM namespace and Tiller secret 
export MCM_NAMESPACE=mcm
export KLUSTERLET_TILLER_SECRET=secret
kubectl create secret tls ${KLUSTERLET_TILLER_SECRET} \
    --cert ~/.helm/cert.pem --key ~/.helm/key.pem -n kube-system
kubectl create namespace ${MCM_NAMESPACE}




# Add and install helm chart
export CLUSTER_NAME=mycluster
export CLUSTER_NAMESPACE=kube-system

helm repo add local-charts https://${HUB_CLUSTER_IP}:8443/helm-repo/charts \
    --ca-file ~/.helm/ca.pem --cert-file ~/.helm/cert.pem --key-file ~/.helm/key.pem

if [[ $? -gt 0 ]]; then
    /bin/echo "Error adding local-charts, installing from tarball" >&2
else
    CHARTNAME=local-charts/ibm-mcm-prod
fi

helm repo update

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



# Install CLI
docker run -e LICENSE=accept -v /usr/local/bin:/data \
    mycluster.icp:8500/kube-system/mcmctl:${ICP_VERSION} \
    cp mcmctl-linux-${ARCH} /data/mcmctl


/bin/echo "MCM installation completed"

