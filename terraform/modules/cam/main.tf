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


resource "null_resource" "cam_install_wait" {
    count   = "${var.cam_docker_user != "" || var.cam_download_location != "" ? 1 : 0}"
    provisioner "local-exec" {
        command = "echo ICP install complete status is ${var.icp_status}"
    }
}


resource "null_resource" "cam_install" {
    depends_on = ["null_resource.cam_install_wait"]
    count   = "${var.cam_docker_user != "" || var.cam_download_location != "" ? 1 : 0}"

    connection {
        host          = "${var.icp_master}"
        user          = "${var.ssh_user}"
        private_key   = "${base64decode(var.ssh_key_base64)}"
        agent         = "${var.ssh_agent}"
        bastion_host  = "${var.bastion_host}"
    }

    provisioner "file" {
        source = "${path.module}/scripts/cam_install.sh"
        destination = "/tmp/cam_install.sh"
    }

    provisioner "file" {
        when = "destroy"
        source = "${path.module}/scripts/cam_cleanup.sh"
        destination = "/tmp/cam_cleanup.sh"
    }

    provisioner "remote-exec" {
        inline = [
          "chmod 755 /tmp/cam_install.sh",
          "if [ ! -z '${var.cam_docker_user}' ]; then bash -c '/tmp/cam_install.sh ONLINE ${var.icp_master} ${var.cam_version} ${var.cluster_name} ${var.icp_admin_user}  ${var.icp_admin_user_password} ${var.cam_docker_user} ${var.cam_docker_password} ${var.cam_docker_secret} ${var.cam_product_id}'; fi",
          "if [ ! -z ${var.cam_download_location} ] && [ -z ${var.cam_docker_user} ]; then bash -c '/tmp/cam_install.sh OFFLINE ${var.icp_master} ${var.cam_version} ${var.cluster_name} ${var.icp_admin_user} ${var.icp_admin_user_password} ${var.cam_download_location} ${var.cam_download_user} ${var.cam_download_password} ${var.cam_product_id}'; fi"
        ]
    }

    provisioner "remote-exec" {
        when = "destroy"
        inline = [
          "chmod 755 /tmp/cam_cleanup.sh",
          "bash -c '/tmp/cam_cleanup.sh ${var.icp_master} ${var.icp_admin_user} ${var.icp_admin_user_password} ${var.cam_docker_secret}'"
        ]
    }
}
