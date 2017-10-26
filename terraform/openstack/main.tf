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

resource "random_id" "rand" {
    byte_length = 2
}

resource "openstack_compute_keypair_v2" "icp-key-pair" {
    name       = "terraform-icp-key-pair-${random_id.rand.hex}"
    public_key = "${file("${var.openstack_ssh_key_file}.pub")}"
}

resource "openstack_compute_instance_v2" "icp-worker-vm" {
    count     = "${var.icp_num_workers}"
    name      = "${format("terraform-icp-worker-${random_id.rand.hex}-%02d", count.index+1)}"
    image_id  = "${var.openstack_image_id}"
    flavor_id = "${var.openstack_flavor_id_worker_node}"
    key_pair  = "${openstack_compute_keypair_v2.icp-key-pair.name}"

    network {
        name = "${var.openstack_network_name}"
    }

    user_data = "${file("bootstrap_icp_worker.sh")}"
}

resource "openstack_compute_instance_v2" "icp-master-vm" {
    name      = "terraform-icp-master-${random_id.rand.hex}"
    image_id  = "${var.openstack_image_id}"
    flavor_id = "${var.openstack_flavor_id_master_node}"
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
        name = "${var.openstack_network_name}"
    }

    user_data = "${file("bootstrap_icp_ce_master.sh")}"
}
