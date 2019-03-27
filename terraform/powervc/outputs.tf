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

output "icp_master_vm_ip" {
    value = "${openstack_compute_instance_v2.icp_master_vm.network.0.fixed_ip_v4}"
}

output "icp_worker_vm_ips" {
    value = "${openstack_compute_instance_v2.icp_worker_vm.*.network.0.fixed_ip_v4}"
}

output "icp_default_admin_password" {
    value = "${module.icpprovision.default_admin_password}"
}
