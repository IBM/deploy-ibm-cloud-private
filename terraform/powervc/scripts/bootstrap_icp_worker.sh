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

# Enable NTP
/usr/bin/timedatectl set-ntp on
# Need to set vm.max_map_count to at least 262144
/sbin/sysctl -w vm.max_map_count=262144
/bin/echo "vm.max_map_count=262144" | /usr/bin/tee -a /etc/sysctl.conf

if [ -f /etc/redhat-release ]; then
    # Disable the firewall
    systemctl stop firewalld
    systemctl disable firewalld
    # Make sure we're not running some old version of docker
    yum -y remove docker docker-engine docker.io
    yum -y install moreutils
    # Either install the icp docker version or from the repo
    if [ ! -z ${docker_download_location} ]; then
        TMP_DIR="$(/bin/mktemp -d)"
        cd "$TMP_DIR"
        /usr/bin/wget -q "${docker_download_location}"
        chmod +x *
        ./*.bin --install
        /bin/rm -rf "$TMP_DIR"
    else
        yum -y install docker-ce
    fi
    systemctl start docker
elif [ -f /etc/SuSE-release ]; then
    systemctl stop SuSEfirewall2
    systemctl disable SuSEfirewall2
    zypper -n remove docker docker-engine docker.io
    zypper -n install moreutils
    if [ ! -z ${docker_download_location} ]; then
        TMP_DIR="$(/bin/mktemp -d)"
        cd "$TMP_DIR"
        /usr/bin/wget -q "${docker_download_location}"
        chmod +x *
        ./*.bin --install
        /bin/rm -rf "$TMP_DIR"
    else
        zypper -n install docker
    fi
    systemctl start docker
else
    /usr/sbin/ufw disable
    # Prepare the system for updates, install Docker and install Python
    /usr/bin/apt update
    # We'll use docker-ce (vs docker.io as ce/ee is what is supported by ICP)
    /usr/bin/apt-get --assume-yes purge docker
    /usr/bin/apt-get --assume-yes purge docker-engine
    /usr/bin/apt-get --assume-yes purge docker.io
    /usr/bin/apt-get --assume-yes install apt-transport-https moreutils\
    ca-certificates curl software-properties-common python python-pip
    if [ ! -z ${docker_download_location} ]; then
        TMP_DIR="$(/bin/mktemp -d)"
        cd "$TMP_DIR"
        /usr/bin/wget -q "${docker_download_location}"
        chmod +x *
        ./*.bin --install
        /bin/rm -rf "$TMP_DIR"
    else
        # Add Docker GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        # Add the repo
        /usr/bin/add-apt-repository \
        "deb https://download.docker.com/linux/ubuntu \
         $(lsb_release -cs) stable"
        /usr/bin/apt update
        /usr/bin/apt-get --assume-yes install docker-ce
    fi
fi

touch /tmp/CLOUDINIT_DONE

exit 0
