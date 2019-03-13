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

################################################################
## Generate local map
################################################################
locals {
    depends_on = ["null_resource.wait-for-master"]
    config = {
        "default_admin_password"    = "${var.icp_default_admin_password}"
        "ansible_user"              = "${var.icp_install_user}"
        "ansible_become"            = "true"
        "ansible_become_password"   = "${var.icp_install_user_password}"
        "management_services"       = "${var.icp_management_services}"
    }
}

################################################################
## Call the ICP Deployment module
################################################################
module "icpprovision" {
    source                  = "github.com/ibm-cloud-architecture/terraform-module-icp-deploy?ref=3.0.8"

    icp-master              = ["${openstack_compute_instance_v2.icp_master_vm.network.0.fixed_ip_v4}"]
    icp-worker              = ["${openstack_compute_instance_v2.icp_worker_vm.*.network.0.fixed_ip_v4}"]
    icp-proxy               = ["${openstack_compute_instance_v2.icp_master_vm.network.0.fixed_ip_v4}"]

    cluster_size            = "${openstack_compute_instance_v2.icp_master_vm.count + openstack_compute_instance_v2.icp_worker_vm.count}"

    icp_configuration       = "${local.config}"

    icp-inception           = "${var.icp_version}"
    generate_key            = "false"
    icp_priv_key            = "${file(var.openstack_ssh_key_file)}"
    icp_pub_key             = "${file("${var.openstack_ssh_key_file}.pub")}"
    ssh_user                = "${var.icp_install_user}"
    ssh_key_base64          = "${base64encode(file(var.openstack_ssh_key_file))}"
    ssh_agent               = "false"

    # Docker is configured with local bootstrap files for all supported OS
    #docker_package_location = "${var.docker_download_location}"
    
    image_location = "${var.icp_download_location}"

    hooks = {
        cluster-preconfig = ["echo 'DEBUG: cluster-preconfig'"]
        cluster-postconfig = ["echo 'DEBUG: cluster-postconfig'"]
        boot-preconfig = ["echo 'DEBUG: boot-preconfig'"]
        preinstall = ["echo 'DEBUG: preinstall'"]
        postinstall = ["echo 'DEBUG: postinstall'"]
    }
}

module "mcm_install" {
    source                  = "../modules/mcm"

    icp_status              = "${module.icpprovision.install_complete}"
    ssh_user                = "${var.icp_install_user}"
    ssh_key_base64          = "${base64encode(file(var.openstack_ssh_key_file))}"
    ssh_agent               = "false"
    icp_master              = "${openstack_compute_instance_v2.icp_master_vm.network.0.fixed_ip_v4}"
    icp_version             = "${var.icp_version}"
    cluster_name            = "mycluster"
    icp_admin_user          = "admin"
    icp_admin_user_password = "${module.icpprovision.default_admin_password}"
    mcm_secret              = "secret"
    mcm_namespace           = "mcm"
    mcm_cluster_namespace   = "cmcm"
    mcm_download_location   = "${var.mcm_download_location}"
    mcm_download_user       = "${var.mcm_download_user}"
    mcm_download_password   = "${var.mcm_download_password}"
}

module "cam_install" {
    source                  = "../modules/cam"

    icp_status              = "${module.icpprovision.install_complete}"
    ssh_user                = "${var.icp_install_user}"
    ssh_key_base64          = "${base64encode(file(var.openstack_ssh_key_file))}"
    ssh_agent               = "false"
    icp_master              = "${openstack_compute_instance_v2.icp_master_vm.network.0.fixed_ip_v4}"
    cluster_name            = "mycluster"
    icp_admin_user          = "admin"
    icp_admin_user_password = "${module.icpprovision.default_admin_password}"
    cam_version             = "${var.cam_version}"
    cam_docker_user         = "${var.cam_docker_user}"
    cam_docker_password     = "${var.cam_docker_password}"
    cam_docker_secret       = "camdockersecret"
    cam_download_location   = "${var.cam_download_location}"
    cam_download_user       = "${var.cam_download_user}"
    cam_download_password   = "${var.cam_download_password}"
    cam_product_id          = "${var.cam_product_id}"
}
