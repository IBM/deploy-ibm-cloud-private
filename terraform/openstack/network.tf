# Create floating ip master
resource "openstack_networking_floatingip_v2" "master_pub_ip" {
    count = "1"
    pool  = "${var.openstack_floating_network_name}"
}
# Assign floating ip to master
resource "openstack_compute_floatingip_associate_v2" "master_pub_ip" {
    count       = "1"
    floating_ip = "${openstack_networking_floatingip_v2.master_pub_ip.*.address[count.index]}"
    instance_id = "${openstack_compute_instance_v2.icp_master_vm.*.id[count.index]}"
}
