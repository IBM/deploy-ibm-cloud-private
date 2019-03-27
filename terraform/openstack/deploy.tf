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
# Yussuf Shaikh <yussuf@us.ibm.com> - Allow Klusterlet only install.
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
        "cluster_lb_address"        = "${openstack_compute_floatingip_associate_v2.master_pub_ip.0.floating_ip}"
    }
}

################################################################
## Call the ICP Deployment module
################################################################
module "icpprovision" {
    source                  = "github.com/ibm-cloud-architecture/terraform-module-icp-deploy?ref=3.0.8"

    icp-host-groups = {
        master      = "${openstack_compute_instance_v2.icp_master_vm.*.network.0.fixed_ip_v4}"
        management  = "${split(" ", var.openstack_management_node["count"] == "0" ? join(" ", openstack_compute_instance_v2.icp_master_vm.*.network.0.fixed_ip_v4) : join(" ", openstack_compute_instance_v2.icp_management_vm.*.network.0.fixed_ip_v4))}"
        worker      = "${split(" ", var.openstack_worker_node["count"] == "0" ? join(" ", openstack_compute_instance_v2.icp_master_vm.*.network.0.fixed_ip_v4) : join(" ", openstack_compute_instance_v2.icp_worker_vm.*.network.0.fixed_ip_v4))}"
        proxy       = "${split(" ", var.openstack_proxy_node["count"] == "0" ? join(" ", openstack_compute_instance_v2.icp_master_vm.*.network.0.fixed_ip_v4) : join(" ", openstack_compute_instance_v2.icp_proxy_vm.*.network.0.fixed_ip_v4))}"
        va          = "${split(" ", var.openstack_va_node["count"] == "0" ? join(" ", openstack_compute_instance_v2.icp_master_vm.*.network.0.fixed_ip_v4) : join(" ", openstack_compute_instance_v2.icp_va_vm.*.network.0.fixed_ip_v4))}"
    }
    boot-node = "${openstack_compute_instance_v2.icp_master_vm.0.network.0.fixed_ip_v4}"
    cluster_size            = "${openstack_compute_instance_v2.icp_master_vm.count + var.openstack_worker_node["count"] + var.openstack_management_node["count"] + var.openstack_proxy_node["count"] + var.openstack_va_node["count"]}"

    icp_configuration       = "${merge(local.config, var.icp_configuration)}"

    icp-inception           = "${var.icp_version}"
    generate_key            = "false"
    icp_priv_key            = "${file(var.openstack_ssh_key_file)}"
    icp_pub_key             = "${file("${var.openstack_ssh_key_file}.pub")}"
    ssh_user                = "${var.icp_install_user}"
    ssh_key_base64          = "${base64encode(file(var.openstack_ssh_key_file))}"
    ssh_agent               = "false"
    bastion_host            = "${openstack_compute_floatingip_associate_v2.master_pub_ip.0.floating_ip}"

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
    icp_admin_user          = "admin"
    icp_admin_user_password = "${module.icpprovision.default_admin_password}"
    klusterlet_only         = "${var.mcm_klusterlet_only}"
    klusterlet_name         = "${var.mcm_klusterlet_name}"
    namespace               = "${var.mcm_namespace}"
    server_url              = "${var.mcm_hub_server_url}"
    server_token            = "${var.mcm_hub_server_token}"
    mcm_download_location   = "${var.mcm_download_location}"
    mcm_download_user       = "${var.mcm_download_user}"
    mcm_download_password   = "${var.mcm_download_password}"
    bastion_host            = "${openstack_compute_floatingip_associate_v2.master_pub_ip.0.floating_ip}"
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
    bastion_host            = "${openstack_compute_floatingip_associate_v2.master_pub_ip.0.floating_ip}"
}
