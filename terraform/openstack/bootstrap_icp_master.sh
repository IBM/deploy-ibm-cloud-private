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

# The IBM Cloud Private embedded Docker image
# (ibmcom/icp-inception for x86 or ibmcom/icp-inception-ppc64le for Power)
if [ "${icp_architecture}" == "ppc64le" ]; then
    ICP_DOCKER_IMAGE="ibmcom/icp-inception-ppc64le:${icp_version}"
else
    ICP_DOCKER_IMAGE="ibmcom/icp_inception:${icp_version}"
fi
if [ "${icp_edition}" == "ee" ]; then
    ICP_DOCKER_IMAGE="$ICP_DOCKER_IMAGE-ee"
fi

# Root directory of ICP installation
ICP_ROOT_DIR="/opt/ibm-cloud-private-${icp_edition}"

# Disable the firewall
/usr/sbin/ufw disable
# Enable NTP
/usr/bin/timedatectl set-ntp on
# Need to set vm.max_map_count to at least 262144
/sbin/sysctl -w vm.max_map_count=262144
/bin/echo "vm.max_map_count=262144" | /usr/bin/tee -a /etc/sysctl.conf
# Prepare the system for updates, install Docker and install Python
/usr/bin/apt update
# We'll use docker-ce (vs docker.io as ce/ee is what is supported by ICP)
# Make sure we're not running some old version of docker
/usr/bin/apt-get --assume-yes purge docker
/usr/bin/apt-get --assume-yes purge docker-engine
/usr/bin/apt-get --assume-yes purge docker.io
/usr/bin/apt-get --assume-yes install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
# Add docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# Add the repo
/usr/bin/add-apt-repository \
   "deb https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
/usr/bin/apt update
/usr/bin/apt-get --assume-yes install docker-ce python python-pip

# Ensure the hostnames are resolvable
IP=`/sbin/ifconfig eth0 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}'`
/bin/echo "$IP $(hostname)" >> /etc/hosts

# Download and configure IBM Cloud Private
if [ "${icp_edition}" == "ee" ]; then
    TMP_DIR="$(/bin/mktemp -d)"
    cd "$TMP_DIR"
    /usr/bin/wget -q "${icp_download_location}"
    /bin/tar xf *.tar.gz -O | /usr/bin/docker load
else
    /usr/bin/docker pull $ICP_DOCKER_IMAGE
fi

/bin/mkdir "$ICP_ROOT_DIR"
cd "$ICP_ROOT_DIR"
/usr/bin/docker run -e LICENSE=accept -v \
    "$(pwd)":/data $ICP_DOCKER_IMAGE cp -r cluster /data

if [ "${icp_edition}" == "ee" ]; then
    /bin/mkdir -p cluster/images
    /bin/mv $TMP_DIR/*.tar.gz $ICP_ROOT_DIR/cluster/images/
    /bin/rm -rf "$TMP_DIR"
fi

# Configure the master and proxy as the same node
/bin/echo "[master]"  > cluster/hosts
/bin/echo "$IP"    >> cluster/hosts
/bin/echo "[proxy]"  >> cluster/hosts
/bin/echo "$IP"    >> cluster/hosts
# Configure the worker node(s)
for worker_ip in $( cat /root/icp_worker_nodes.txt | sed 's/|/\n/g' ); do
    /bin/echo "[worker]"     >> cluster/hosts
    /bin/echo "$worker_ip" >> cluster/hosts
done

# Modify config.yaml with appropriate variables - these come from the template
/bin/sed -i 's/.*ansible_user:.*/ansible_user: "'${install_user_name}'"/g' cluster/config.yaml
/bin/sed -i 's/.*ansible_become:.*/ansible_become: true/g' cluster/config.yaml
if [ -n "${install_user_password}" ]; then
    /bin/sed -i 's/.*ansible_become_password:.*/ansible_become_password: "'${install_user_password}'"/g' cluster/config.yaml
fi

# Setup the private key for the ICP cluster (injected at deploy time)
/bin/cp /root/id_rsa.terraform \
    $ICP_ROOT_DIR/cluster/ssh_key
/bin/chmod 400 $ICP_ROOT_DIR/cluster/ssh_key

# Deploy IBM Cloud Private
cd "$ICP_ROOT_DIR/cluster"
/usr/bin/docker run -e LICENSE=accept --net=host -t -v \
    "$(pwd)":/installer/cluster $ICP_DOCKER_IMAGE install | \
    /usr/bin/tee install.log

exit 0
