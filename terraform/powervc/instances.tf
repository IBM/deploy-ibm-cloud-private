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
#
################################################################

################################################################
# Create Master Nodes
################################################################
resource "openstack_compute_instance_v2" "icp_master_vm" {
    name      = "${var.instance_prefix}-master-${random_id.rand.hex}"
    image_id  = "${var.openstack_image_id}"
    flavor_id = "${var.openstack_master_node["flavor_id"]}"
    key_pair  = "${openstack_compute_keypair_v2.icp-key-pair.name}"
    network {
        name = "${var.openstack_network_name}"
    }
    user_data = "${data.template_file.bootstrap_init.rendered}"
}

data "template_file" "bootstrap_init" {
    template = "${file("scripts/bootstrap_icp_master.sh")}"
    vars {
        icp_architecture = "${var.icp_architecture}"
        docker_download_location = "${var.docker_download_location}"
        smt_value_master = "${var.smt_value_master}"
    }
}

resource "null_resource" "wait_for_master" {
    provisioner "remote-exec" {
        connection {
            host        = "${openstack_compute_instance_v2.icp_master_vm.network.0.fixed_ip_v4}"
            user        = "${var.icp_install_user}"
            private_key = "${file(var.openstack_ssh_key_file)}"
            agent       = "false"
            timeout     = "15m"
        }

        inline = [
          "while [ ! -f /tmp/CLOUDINIT_DONE ]; do sleep 5; done",
        ]
    }
}

################################################################
# Create Worker Nodes
################################################################
resource "openstack_compute_instance_v2" "icp_worker_vm" {
    count     = "${var.openstack_worker_node["count"]}"
    depends_on = ["null_resource.wait_for_master"]

    name      = "${format("${var.instance_prefix}-worker-${random_id.rand.hex}-%02d", count.index+1)}"
    image_id  = "${var.openstack_image_id}"
    flavor_id = "${var.openstack_worker_node["flavor_id"]}"
    key_pair  = "${openstack_compute_keypair_v2.icp-key-pair.name}"
    network {
        name = "${var.openstack_network_name}"
    }
    user_data = "${data.template_file.bootstrap_worker.rendered}"

    provisioner "remote-exec" {
        connection {
            host          = "${self.access_ip_v4}"
            user          = "${var.icp_install_user}"
            private_key   = "${file(var.openstack_ssh_key_file)}"
            agent         = "false"
            timeout     = "15m"
        }

        inline = [
          "while [ ! -f /tmp/CLOUDINIT_DONE ]; do sleep 5; done",
        ]
    }
}

data "template_file" "bootstrap_worker" {
    template = "${file("scripts/bootstrap_icp_worker.sh")}"
    vars {
        docker_download_location = "${var.docker_download_location}"
    }
}

################################################################
# Create Management Nodes
################################################################
resource "openstack_compute_instance_v2" "icp_management_vm" {
    count     = "${var.openstack_management_node["count"]}"
    depends_on = ["null_resource.wait_for_master"]

    name      = "${format("${var.instance_prefix}-management-${random_id.rand.hex}-%02d", count.index+1)}"
    image_id  = "${var.openstack_image_id}"
    flavor_id = "${var.openstack_management_node["flavor_id"]}"
    key_pair  = "${openstack_compute_keypair_v2.icp-key-pair.name}"
    network {
        name = "${var.openstack_network_name}"
    }
    user_data = "${data.template_file.bootstrap_worker.rendered}"

    provisioner "remote-exec" {
        connection {
            host          = "${self.access_ip_v4}"
            user          = "${var.icp_install_user}"
            private_key   = "${file(var.openstack_ssh_key_file)}"
            agent         = "false"
            timeout     = "15m"
        }

        inline = [
          "while [ ! -f /tmp/CLOUDINIT_DONE ]; do sleep 5; done",
        ]
    }
}

################################################################
# Create Proxy Nodes
################################################################
resource "openstack_compute_instance_v2" "icp_proxy_vm" {
    count     = "${var.openstack_proxy_node["count"]}"
    depends_on = ["null_resource.wait_for_master"]

    name      = "${format("${var.instance_prefix}-proxy-${random_id.rand.hex}-%02d", count.index+1)}"
    image_id  = "${var.openstack_image_id}"
    flavor_id = "${var.openstack_proxy_node["flavor_id"]}"
    key_pair  = "${openstack_compute_keypair_v2.icp-key-pair.name}"
    network {
        name = "${var.openstack_network_name}"
    }
    user_data = "${data.template_file.bootstrap_worker.rendered}"

    provisioner "remote-exec" {
        connection {
            host          = "${self.access_ip_v4}"
            user          = "${var.icp_install_user}"
            private_key   = "${file(var.openstack_ssh_key_file)}"
            agent         = "false"
            timeout     = "15m"
        }

        inline = [
          "while [ ! -f /tmp/CLOUDINIT_DONE ]; do sleep 5; done",
        ]
    }
}

################################################################
# Create VA Nodes
################################################################
resource "openstack_compute_instance_v2" "icp_va_vm" {
    count     = "${var.openstack_va_node["count"]}"
    depends_on = ["null_resource.wait_for_master"]

    name      = "${format("${var.instance_prefix}-va-${random_id.rand.hex}-%02d", count.index+1)}"
    image_id  = "${var.openstack_image_id}"
    flavor_id = "${var.openstack_va_node["flavor_id"]}"
    key_pair  = "${openstack_compute_keypair_v2.icp-key-pair.name}"
    network {
        name = "${var.openstack_network_name}"
    }
    user_data = "${data.template_file.bootstrap_worker.rendered}"

    provisioner "remote-exec" {
        connection {
            host          = "${self.access_ip_v4}"
            user          = "${var.icp_install_user}"
            private_key   = "${file(var.openstack_ssh_key_file)}"
            agent         = "false"
            timeout     = "15m"
        }

        inline = [
          "while [ ! -f /tmp/CLOUDINIT_DONE ]; do sleep 5; done",
        ]
    }
}
