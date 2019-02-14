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

#Set SMT level for master
/usr/sbin/ppc64_cpu --smt=${SMTvalue_master}

cat >> /etc/systemd/system/smt.service <<EOL
[Unit]
Description=Disable SMT
After=syslog.target
[Service]
Type=simple
ExecStart=/usr/sbin/ppc64_cpu --smt=${SMTvalue_master}
TimeoutSec=300
[Install]
WantedBy=multi-user.target
EOL

/bin/systemctl daemon-reload
/bin/systemctl enable smt.service

# Determine icp version
IFS='.' read -r -a iver <<< ${icp_version}
# fill in any empty digits (some only had 3)
for i in 0 1 2 3
do
    if [ -z $${iver[i]} ] ; then
        iver[$i]=0
    fi
done

# Determine the IBM Cloud Private embedded Docker image name
ARCH_POSTFIX=""
ICP_DOCKER_IMAGE="ibmcom/icp-inception"
# For IBM Power, append ppc64le for ICP versions 2.1.0.2 and earlier
if [ "${icp_architecture}" == "ppc64le" ] &&  [ "$${iver[0]}" -le "2" ] &&
    [ "$${iver[1]}" -le "1" ] && [ "$${iver[2]}" -le "0" ] && [ "$${iver[3]}" -le "2" ]; then
    ARCH_POSTFIX="-ppc64le"
fi
# For ICP ee, versions 3.x and beyond requires ARCH, for 2.1.0.3 ARCH is not needed
if [ "${icp_edition}" == "ee" ]; then
    if [ "$${iver[0]}" -ge "3" ]; then
        ARCH_POSTFIX="-"${icp_architecture}
    fi
    ICP_DOCKER_IMAGE="$ICP_DOCKER_IMAGE$ARCH_POSTFIX:${icp_version}-ee"
else
    ICP_DOCKER_IMAGE="$ICP_DOCKER_IMAGE$ARCH_POSTFIX:${icp_version}"
fi

# Root directory of ICP installation
ICP_ROOT_DIR="/opt/ibm-cloud-private-${icp_edition}"

# Enable NTP
/usr/bin/timedatectl set-ntp on
# Need to set vm.max_map_count to at least 262144
/sbin/sysctl -w vm.max_map_count=262144
/bin/echo "vm.max_map_count=262144" | /usr/bin/tee -a /etc/sysctl.conf

# Now for distro dependent stuff
if [ -f /etc/redhat-release ]; then
#RHEL specific steps
    # Disable the firewall
    systemctl stop firewalld
    systemctl disable firewalld
    # Make sure we're not running some old version of docker
    yum -y remove docker docker-engine docker.io
    yum -y install socat 
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
#SLES specific steps
    # Disable the firewall
    systemctl stop SuSEfirewall2
    systemctl disable SuSEfirewall2
    # Make sure we're not running some old version of docker
    zypper -n remove docker docker-engine docker.io
    zypper -n install socat
    # Either install the icp docker version or from the repo
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
# Ubuntu specific steps
    # Disable the firewall
    /usr/sbin/ufw disable
    # Prepare the system for updates, install Docker and install Python
    /usr/bin/apt update
    # Make sure we're not running some old version of docker
    /usr/bin/apt-get --assume-yes purge docker
    /usr/bin/apt-get --assume-yes purge docker-engine
    /usr/bin/apt-get --assume-yes purge docker.io
    /usr/bin/apt-get --assume-yes install apt-transport-https \
    ca-certificates curl software-properties-common python python-pip

    # Either install the icp docker version or from the repo
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

# Ensure the hostnames are resolvable
IP=`hostname -I | cut -f 1 -d ' '`
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
/bin/echo "[va]"  >> cluster/hosts
/bin/echo "$IP"    >> cluster/hosts
/bin/echo "[proxy]"  >> cluster/hosts
/bin/echo "$IP"    >> cluster/hosts

x=0
while [ "$x" -lt 100 -a ! -f /tmp/icp_worker_nodes.txt ]; do
   x=$((x+1))
   /bin/sleep 1
done

# Configure the worker node(s)
for worker_ip in $( cat /tmp/icp_worker_nodes.txt | sed 's/|/\n/g' ); do
    x=0
    while [ "$x" -lt 100 ] && ! ping -c 1 -W 1 $worker_ip; do
       x=$((x+1))
       /bin/echo "$worker_ip is unreachable, trying after 10s"
       /bin/sleep 10
    done
    /bin/echo "[worker]"     >> cluster/hosts
    /bin/echo "$worker_ip" >> cluster/hosts
done

# Modify config.yaml with appropriate variables - these come from the template
/bin/sed -i 's/.*ansible_user:.*/ansible_user: "'${install_user_name}'"/g' cluster/config.yaml
/bin/sed -i 's/.*ansible_become:.*/ansible_become: true/g' cluster/config.yaml
if [ -n "${install_user_password}" ]; then
    /bin/sed -i 's/.*ansible_become_password:.*/ansible_become_password: "'${install_user_password}'"/g' cluster/config.yaml
fi
if [ -n "${icp_disabled_services}" ]; then
    /bin/sed -i 's/.*disabled_management_services:.*/disabled_management_services: [ ${icp_disabled_services} ]/g' cluster/config.yaml
else
    /bin/sed -i 's/.*disabled_management_services:.*/disabled_management_services: [ "" ]/g' cluster/config.yaml

fi

# Setup the private key for the ICP cluster (injected at deploy time)
/bin/cp /tmp/id_rsa.terraform \
    $ICP_ROOT_DIR/cluster/ssh_key
/bin/chmod 400 $ICP_ROOT_DIR/cluster/ssh_key

# Deploy IBM Cloud Private
cd "$ICP_ROOT_DIR/cluster"
/usr/bin/docker run -e LICENSE=accept --net=host -t -v \
    "$(pwd)":/installer/cluster $ICP_DOCKER_IMAGE install | \
    /usr/bin/tee install.log

if [ ! -z ${mcm_download_location} ]; then
    chmod a+x /tmp/install_mcm.sh
    /tmp/install_mcm.sh $IP ${icp_version} ${mcm_download_location} \
        ${mcm_download_user} ${mcm_download_password} | \
        /usr/bin/tee mcm_install.log
fi

if [ ! -z ${cam_docker_user} ]; then
    chmod a+x /tmp/install_cam.sh
    /tmp/install_cam.sh ONLINE $IP ${cam_version} ${cam_docker_user} ${cam_docker_password} \
        ${cam_product_id} | /usr/bin/tee cam_install.log
elif [ ! -z ${cam_download_location} ]; then
    chmod a+x /tmp/install_cam.sh
    /tmp/install_cam.sh OFFLINE $IP ${cam_version} ${cam_download_location} \
        ${cam_download_user} ${cam_download_password} ${cam_product_id} | \
        /usr/bin/tee cam_install.log
fi

exit 0
