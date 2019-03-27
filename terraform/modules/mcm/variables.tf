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
# Yussuf Shaikh <yussuf@us.ibm.com> - Allow Klusterlet only install.
#
################################################################

variable "icp_status" {
    default = ""
}

variable "icp_master" {
    default = ""
}

variable "ssh_user" {
    default = "root"
}

variable "ssh_key_base64" {
    default = ""
}

variable "ssh_agent" {
    default = "false"
}

variable "bastion_host" {
    default = ""
}

variable "icp_version" {
    default = ""
}

variable "icp_admin_user" {
    default = ""
}

variable "icp_admin_user_password" {
    default = ""
}

variable "klusterlet_only" {
    default = "false"
}

variable "klusterlet_name" {
    default = ""
}

variable "namespace" {
    default = ""
}

variable "server_url" {
    default = ""
}

variable "server_token" {
    default = ""
}

variable "mcm_download_location" {
    default = ""
}

variable "mcm_download_user" {
    default = "-"
}

variable "mcm_download_password" {
    default = "-"
}
