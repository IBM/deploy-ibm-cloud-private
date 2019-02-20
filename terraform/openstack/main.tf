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
    name      = "${format("${var.instance_prefix}-worker-${random_id.rand.hex}-%02d", count.index+1)}"
    image_id  = "${var.openstack_image_id}"
    flavor_id = "${var.openstack_flavor_id_worker_node}"
    key_pair  = "${openstack_compute_keypair_v2.icp-key-pair.name}"

    network {
        name = "${var.openstack_network_name}"
    }

    user_data = "${data.template_file.bootstrap_worker.rendered}"

    provisioner "local-exec" {
        command = "if ping -c 1 -W 1 $MASTER_IP; then ssh -o 'StrictHostKeyChecking no' -i $KEY_FILE $USER@$MASTER_IP 'if [[ -f /tmp/icp_worker_scaler.sh ]]; then chmod a+x /tmp/icp_worker_scaler.sh; /tmp/icp_worker_scaler.sh a ${var.icp_edition} ${self.network.0.fixed_ip_v4}; fi'; fi"
        environment {
            MASTER_IP = "${openstack_compute_instance_v2.icp-master-vm.network.0.fixed_ip_v4}"
            USER = "${var.icp_install_user}"
            KEY_FILE = "${var.openstack_ssh_key_file}"
        }
    }

    provisioner "local-exec" {
        when    = "destroy"
        command = "ssh -o 'StrictHostKeyChecking no' -i $KEY_FILE $USER@$MASTER_IP 'if [[ -f /tmp/icp_worker_scaler.sh ]]; then chmod a+x /tmp/icp_worker_scaler.sh; /tmp/icp_worker_scaler.sh r ${var.icp_edition} ${self.network.0.fixed_ip_v4}; fi'"
        environment {
            MASTER_IP = "${openstack_compute_instance_v2.icp-master-vm.network.0.fixed_ip_v4}"
            USER = "${var.icp_install_user}"
            KEY_FILE = "${var.openstack_ssh_key_file}"
        }
    }
}

resource "openstack_compute_instance_v2" "icp-master-vm" {
    name      = "${var.instance_prefix}-master-${random_id.rand.hex}"
    image_id  = "${var.openstack_image_id}"
    flavor_id = "${var.openstack_flavor_id_master_node}"
    key_pair  = "${openstack_compute_keypair_v2.icp-key-pair.name}"

    network {
        name = "${var.openstack_network_name}"
    }

    user_data = "${data.template_file.bootstrap_init.rendered}"

}

data "template_file" "bootstrap_init" {
    template = "${file("bootstrap_icp_master.sh")}"

    vars {
        icp_version = "${var.icp_version}"
        icp_architecture = "${var.icp_architecture}"
        icp_edition = "${var.icp_edition}"
        icp_download_location = "${var.icp_download_location}"
        icp_default_admin_password = "${var.icp_default_admin_password}"
        icp_disabled_services = "${join(", ",formatlist("\"%s\"",var.icp_disabled_services))}"
        install_user_name = "${var.icp_install_user}"
        install_user_password = "${var.icp_install_user_password}"
        docker_download_location = "${var.docker_download_location}"
        mcm_download_location = "${var.mcm_download_location}"
        mcm_download_user = "${var.mcm_download_user}"
        mcm_download_password = "${var.mcm_download_password}"
        cam_version = "${var.cam_version}"
        cam_docker_user = "${var.cam_docker_user}"
        cam_docker_password = "${var.cam_docker_password}"
        cam_product_id = "${var.cam_product_id}"
        cam_download_location = "${var.cam_download_location}"
        cam_download_user = "${var.cam_download_user}"
        cam_download_password = "${var.cam_download_password}"
        smt_value_master = "${var.smt_value_master}"
    }
}

data "template_file" "bootstrap_worker" {
    template = "${file("bootstrap_icp_worker.sh")}"

    vars {
        docker_download_location = "${var.docker_download_location}"
    }
}

resource "null_resource" "icp-worker-scaler" {
    triggers {
        workers = "${join("|", openstack_compute_instance_v2.icp-worker-vm.*.network.0.fixed_ip_v4)}"
    }

    connection {
        type            = "ssh"
        user            = "${var.icp_install_user}"
        host            = "${openstack_compute_instance_v2.icp-master-vm.*.network.0.fixed_ip_v4}"
        private_key     = "${file(var.openstack_ssh_key_file)}"
        timeout         = "15m"
    }

    provisioner "file" {
        source      = "${path.module}/icp_worker_scaler.sh"
        destination = "/tmp/icp_worker_scaler.sh"
    }

    provisioner "file" {
        content     = "${join("|", openstack_compute_instance_v2.icp-worker-vm.*.network.0.fixed_ip_v4)}"
        destination = "/tmp/icp_worker_nodes.txt"
    }

    provisioner "file" {
        content     = "${file("${var.openstack_ssh_key_file}")}"
        destination = "/tmp/id_rsa.terraform"
    }

    provisioner "file" {
        source      = "${path.module}/install_mcm.sh"
        destination = "/tmp/install_mcm.sh"
    }

    provisioner "file" {
        source      = "${path.module}/install_cam.sh"
        destination = "/tmp/install_cam.sh"
    }
}
