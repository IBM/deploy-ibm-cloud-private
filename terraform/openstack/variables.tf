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
# Yussuf Shaikh <yussuf@us.ibm.com> - Added Management, Proxy, VA nodes.
# Yussuf Shaikh <yussuf@us.ibm.com> - Added icp_configuration map variable.
# Yussuf Shaikh <yussuf@us.ibm.com> - Allow Klusterlet only install.
#
################################################################

################################################################
# Configure the OpenStack Provider
################################################################
variable "openstack_user_name" {
    description = "The user name used to connect to OpenStack"
    default = "my_user_name"
}

variable "openstack_password" {
    description = "The password for the user"
    default = "my_password"
}

variable "openstack_project_name" {
    description = "The name of the project (a.k.a. tenant) used"
    default = "ibm-default"
}

variable "openstack_domain_name" {
    description = "The domain to be used"
    default = "Default"
}

variable "openstack_auth_url" {
    description = "The endpoint URL used to connect to OpenStack"
    default = "https://<HOSTNAME>:5000/v3/"
}


################################################################
# Configure the Instance details
################################################################
variable "instance_prefix" {
    description = "Prefix to use in instance names"
    default = "icp"
}

variable "openstack_image_id" {
    description = "The ID of the image to be used for deploy operations"
    default = "my_image_id"
}

variable "openstack_master_node" {
    type        = "map"
    description = "Map of flavor ID to be used for ICP master node deploy operations"
    default = {
        "flavor_id" = "large"
    }
}

variable "openstack_worker_node" {
    type        = "map"
    description = "Map of count and flavor ID to be used for ICP worker node deploy operations"
    default = {
        "count" = "1"
        "flavor_id" = "large"
    }
}

variable "openstack_management_node" {
    type        = "map"
    description = "Map of count and flavor ID to be used for ICP management node deploy operations"
    default = {
        "count" = "0"
        "flavor_id" = "large"
    }
}

variable "openstack_proxy_node" {
    type        = "map"
    description = "Map of count and flavor ID to be used for ICP proxy node deploy operations"
    default = {
        "count" = "0"
        "flavor_id" = "large"
    }
}

variable "openstack_va_node" {
    type        = "map"
    description = "Map of count and flavor ID to be used for ICP va node deploy operations"
    default = {
        "count" = "0"
        "flavor_id" = "large"
    }
}

variable "openstack_network_name" {
    description = "The name of the network to be used for deploy operations"
    default = "my_network_name"
}

variable "openstack_ssh_key_file" {
    description = "The path to the private SSH key file. Appending '.pub' indicates the public key filename"
    default = "<path to the private SSH key file>"
}

variable "openstack_floating_network_name" {
    description = "The name of floating IP network for master node deploy operation"
    default = "admin_floating_net"
}

variable "openstack_availability_zone" {
    description = "The name of Availability Zone for deploy operation"
    default = "power"
}

variable "openstack_security_groups" {
    description = "The list of security groups that exists on Openstack server for deploy operation"
    default = ["default", "icp-rules"]
}



################################################################
# Configure ICP details
################################################################
variable "icp_install_user" {
    description = "The user with sudo access across nodes (users section of cloud-init)"
    default = "ubuntu"
}

variable "icp_install_user_password" {
   description = "Password for sudo access (leave empty if using passwordless sudo access)"
   default = ""
}

variable "icp_version" {
    description = "ICP version number"
    default = "3.1.2"
}

variable "icp_download_location" {
    description = "HTTP wget location for ICP Enterprise Edition - ignored for community edition"
    default = ""
}

variable "icp_default_admin_password" {
    description = "Password to use for default admin user"
    default = "S3cure-icp-admin-passw0rd-default"
}

variable "icp_management_services" {
    type = "map"
    description = "Map of management services to enable/disable in icp config.yaml"
    default = {
        "istio" = "disabled"
        "metering" = "enabled"
    }
}

variable "icp_configuration" {
    type        = "map"
    description = "Map of configuration values for ICP"
    default = {}
}

variable "docker_download_location" {
    description = "HTTP wget location for ICP provided Docker package"
    default = ""
}


################################################################
# Configure MCM details
################################################################
variable "mcm_download_location" {
    description = "HTTP wget location for MCM tarball"
    default = ""
}

variable "mcm_download_user" {
    description = "Optional username if authentication required for MCM tarball"
    default = "-"
}

variable "mcm_download_password" {
    description = "Optional password if authentication required for MCM tarball"
    default = "-"
}

variable "mcm_klusterlet_only" {
    description = "true if need to install Klusterlet without the Hub cluster(remote)"
    default = "false"
}

variable "mcm_klusterlet_name" {
    description = "Optional name of the Klusterlet."
    default = "mykluster"
}

variable "mcm_namespace" {
    description = "Namespace on Klusterlet (unique) if mcm_klusterlet_only is true. Namespace on the Hub cluster if mcm_klusterlet_only is false"
    default = "mcm"
}

variable "mcm_hub_server_url" {
    description = "If mcm_klusterlet_only is true then Hub cluster URL"
    default = ""
}

variable "mcm_hub_server_token" {
    description = "If mcm_klusterlet_only is true then Hub cluster Token"
    default = ""
}


################################################################
# Configure CAM common details
################################################################
variable "cam_version" {
    default = "3.1.0"
    description = "Version of Cloud Automation Manager to install"
}

variable "cam_product_id" {
    default = ""
    description = "Product Id text for Cloud Automation Manager (EE)"
}

################################################################
# Configure CAM online installation details
################################################################
variable "cam_docker_user" {
    description = "Docker Store user name, needs subscription to CAM"
    default = ""
}

variable "cam_docker_password" {
    description = "Docker Store API key OR password"
    default = ""
}

################################################################
# Configure CAM offline installation details (${cam_docker_user} needs to be empty)
################################################################
variable "cam_download_location" {
    description = "HTTP wget location for CAM tarball"
    default = ""
}

variable "cam_download_user" {
    description = "Optional username if authentication required for CAM tarball"
    default = "-"
}

variable "cam_download_password" {
    description = "Optional password if authentication required for CAM tarball"
    default = "-"
}


################################################################
# Configure SMT level for master node
################################################################
variable "smt_value_master" {
    description = "Number of threads per core. Value can be any of: on, off, 1, 2, 4, 8"
    default = ""
}
