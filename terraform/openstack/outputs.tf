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

output "icp-master-vm-ip" {
    value = "${openstack_compute_instance_v2.icp-master-vm.network.0.fixed_ip_v4}"
}

output "icp-worker-vm-ips" {
    value = "${openstack_compute_instance_v2.icp-worker-vm.*.network.0.fixed_ip_v4}"
}

output "icp_default_admin_password" {
    value = "${var.icp_default_admin_password}"
}
