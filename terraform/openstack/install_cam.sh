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
function init_cam {
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
        --skip-ssl-validation -u admin -p ${icp_default_admin_password} -n services
    docker login mycluster.icp:8500 -u admin -p ${icp_default_admin_password}
}

# Create Docker Store secret
function create_docker_secret {
    export dockersecretname="dockercamsecret"
    kubectl create secret docker-registry -n services ${dockersecretname} \
        --docker-username=${docker_user} --docker-password=${docker_password}
    kubectl patch serviceaccount default -n services -p \
        '{"imagePullSecrets": [{"name": "${dockersecretname}"}]}'
}

# Download and Load PPA archive
function load_ppa_archive {
    wget -nv --continue ${user:+--user} ${user} ${password:+--password} ${password} \
        -O /tmp/cam.tar.gz "${location}"
    if [[ $? -gt 0 ]]; then
        /bin/echo "Error downloading ${location}" >&2
        exit 1
    fi
    cloudctl catalog load-archive -a /tmp/cam.tar.gz
    wget https://mycluster.icp:8443/helm-repo/requiredAssets/ibm-cam-${VERSION}.tgz --no-check-certificate
}

# Add Helm Repos
function add_ibm_chart_repos {
    helm repo add ibm-stable \
        https://raw.githubusercontent.com/IBM/charts/master/repo/stable/
    helm repo add local-charts https://${HUB_CLUSTER_IP}:8443/helm-repo/charts \
        --ca-file ~/.helm/ca.pem --cert-file ~/.helm/cert.pem \
        --key-file ~/.helm/key.pem
    helm fetch ibm-stable/ibm-cam --version ${VERSION}
    helm repo update
}

# Install and configure exportfs; Create Persistent Volumes
function create_persistent_volumes {
    if [ -f /etc/redhat-release ]; then
        yum -y install nfs-utils
    elif [ -f /etc/SuSE-release ]; then
        zypper -n install nfs-kernel-server
    else
        apt-get -y install nfs-kernel-server
    fi

    pvs=( cam-mongo cam-logs cam-terraform cam-bpd-appdata )
    sizes=( 15 10 15 20 )
    dir_names=( db logs terraform BPD_appdata )
    for ((i = 0; i < ${#pvs[@]}; ++i)); do
        item=${pvs[${i}]}
cat > /tmp/${item}-pv.yaml <<EOL
kind: PersistentVolume
apiVersion: v1
metadata:
  name: ${item}-pv
  labels:
    type: ${item}
spec:
  capacity:
    storage: ${sizes[${i}]}Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: mycluster.icp
    path: /export/CAM_${dir_names[${i}]}
EOL
        kubectl create -f /tmp/${item}-pv.yaml
        mkdir -p /export/CAM_${dir_names[${i}]}
    done
    chmod -R 755 /export
cat >> /etc/exports <<EOL
/export *(rw,insecure,no_subtree_check,async,no_root_squash)
/export/CAM_logs *(rw,nohide,insecure,no_subtree_check,async,no_root_squash)
/export/CAM_db *(rw,nohide,insecure,no_subtree_check,async,no_root_squash)
/export/CAM_terraform *(rw,nohide,insecure,no_subtree_check,async,no_root_squash)
/export/CAM_BPD_appdata *(rw,nohide,insecure,no_subtree_check,async,no_root_squash)
EOL
    exportfs -a
}

# Generate a deployment ServiceID API Key
function generate_deployment_key {
    export serviceIDName='service-deploy'
    export serviceApiKeyName='service-deploy-api-key'
    cloudctl iam service-id-create ${serviceIDName} \
        -d 'Service ID for service-deploy'
    cloudctl iam service-policy-create ${serviceIDName} \
        -r Administrator,ClusterAdministrator --service-name 'idmgmt'
    cloudctl iam service-policy-create ${serviceIDName} \
        -r Administrator,ClusterAdministrator --service-name 'identity'
    export deployApiKey=`cloudctl iam service-api-key-create \
        ${serviceApiKeyName} ${serviceIDName} \
        -d 'Api key for service-deploy' | grep 'API Key' | awk '{print $NF}'`
}

# Install Cloud Automation Manager
function install_cam {
    if [ -z ${product_id} ]; then
        helm install ibm-cam-${VERSION}.tgz --name cam --namespace services \
            --set global.image.secretName=${dockersecretname} --set arch=${ARCH} \
            --set global.iam.deployApiKey=${deployApiKey} --tls
    else
        helm install ibm-cam-${VERSION}.tgz --name cam --namespace services \
            --set global.image.secretName=${dockersecretname} --set arch=${ARCH} \
            --set global.iam.deployApiKey=${deployApiKey} \
            --set global.id.productID=${product_id} --tls
    fi
    if [[ $? -gt 0 ]]; then
        /bin/echo "CAM installation failed" >&2
        exit 1
    fi
}


METHOD=$1
HUB_CLUSTER_IP=$2
VERSION=$3
icp_default_admin_password=$4

/bin/echo
/bin/echo "Installing CAM.."
if [ $METHOD == "ONLINE" ]; then
    docker_user=$5
    docker_password=$6
    product_id=$7
    init_cam
    create_docker_secret
    add_ibm_chart_repos
    create_persistent_volumes
    generate_deployment_key
    install_cam
else
    location=$5
    user=$6
    password=$7
    product_id=$8
    init_cam
    load_ppa_archive
    create_persistent_volumes
    generate_deployment_key
    install_cam
fi
/bin/echo "CAM installation completed"
