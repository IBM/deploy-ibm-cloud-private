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

provider "openstack" {
    user_name   = "${var.openstack_user_name}"
    password    = "${var.openstack_password}"
    tenant_name = "${var.openstack_project_name}"
    domain_name = "${var.openstack_domain_name}"
    auth_url    = "${var.openstack_auth_url}"
    insecure    = true
}

resource "openstack_compute_keypair_v2" "icp-key-pair" {
    name       = "terraform-icp-key-pair"
    public_key = "${file("${var.openstack_ssh_key_file}.pub")}"
}

variable "count" {
    default = 3
}

resource "openstack_compute_instance_v2" "icp-worker-vm" {
    count     = "${var.count}"
    name      = "${format("terraform-icp-worker-%02d", count.index+1)}"
    image_id  = "${var.openstack_image_id}"
    flavor_id = "${var.openstack_flavor_id}"
    key_pair  = "${openstack_compute_keypair_v2.icp-key-pair.name}"

    network {
        uuid = "${var.openstack_network_id}"
        name = "${var.openstack_network_name}"
    }

    user_data = "${file("bootstrap_icp_worker.sh")}"
}

resource "openstack_compute_instance_v2" "icp-master-vm" {
    name      = "terraform-icp-master"
    image_id  = "${var.openstack_image_id}"
    flavor_id = "${var.openstack_flavor_id}"
    key_pair  = "${openstack_compute_keypair_v2.icp-key-pair.name}"

    personality {
        file    = "/root/id_rsa.terraform"
        content = "${file("${var.openstack_ssh_key_file}")}"
    }

    personality {
        file    = "/root/icp_worker_nodes.txt"
        content = "${join("|", openstack_compute_instance_v2.icp-worker-vm.*.network.0.fixed_ip_v4)}"
    }

    network {
        uuid = "${var.openstack_network_id}"
        name = "${var.openstack_network_name}"
    }

    user_data = "${file("bootstrap_icp_master.sh")}"
}

output "icp-master-vm-ip" {
    value = "${openstack_compute_instance_v2.icp-master-vm.network.0.fixed_ip_v4}"
}

output "icp-worker-vm-ip" {
    value = "${openstack_compute_instance_v2.icp-worker-vm.*.network.0.fixed_ip_v4}"
}
