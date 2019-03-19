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


resource "null_resource" "mcm_install_wait" {
    count   = "${var.mcm_download_location == "" ? 0 : 1}"
    provisioner "local-exec" {
        command = "echo ICP install complete status is ${var.icp_status}"
    }
}


resource "null_resource" "mcm_install" {
    count   = "${var.mcm_download_location == "" ? 0 : 1}"
    depends_on = ["null_resource.mcm_install_wait"]

    connection {
        host          = "${var.icp_master}"
        user          = "${var.ssh_user}"
        private_key   = "${base64decode(var.ssh_key_base64)}"
        agent         = "${var.ssh_agent}"
        bastion_host  = "${var.bastion_host}"
    }

    provisioner "file" {
        source = "${path.module}/scripts/mcm_install.sh"
        destination = "/tmp/mcm_install.sh"
    }

    provisioner "file" {
        when = "destroy"
        source = "${path.module}/scripts/mcm_cleanup.sh"
        destination = "/tmp/mcm_cleanup.sh"
    }

    provisioner "remote-exec" {
        inline = [
          "chmod 755 /tmp/mcm_install.sh",
          "bash -c '/tmp/mcm_install.sh ${var.icp_master} ${var.icp_version} ${var.cluster_name} ${var.icp_admin_user} ${var.icp_admin_user_password} ${var.mcm_secret} ${var.mcm_namespace} ${var.mcm_cluster_namespace} ${var.mcm_download_location} ${var.mcm_download_user} ${var.mcm_download_password}'"
        ]
    }

    provisioner "remote-exec" {
        when = "destroy"
        inline = [
          "chmod 755 /tmp/mcm_cleanup.sh",
          "bash -c '/tmp/mcm_cleanup.sh ${var.icp_master} ${var.icp_admin_user} ${var.icp_admin_user_password} ${var.mcm_secret} ${var.mcm_namespace} ${var.mcm_cluster_namespace}'"
        ]
    }
}
