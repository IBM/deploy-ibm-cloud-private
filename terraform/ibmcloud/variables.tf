##### SoftLayer Access Credentials ######
variable "sl_username" { default = "" }
variable "sl_api_key" { default = "" }

variable "key_name" {
  description = "Name or reference of SSH key to provision softlayer instances with"
  default = "icp-key"
}

variable "key_file" {
  description = "Path to private key on for above public key"
  default = "/home/username/id_rsa"
}

##### Common VM specifications ######
variable "datacenter" { default = "dal10" }
variable "domain" { default = "icp.demo" }
variable "public_vlan_id" { default = ""}
variable "private_vlan_id" { default = ""}

##### ICP settings #####
variable "icp_version" { default = "ibmcom/icp-inception:2.1.0-beta-3" }

# Name of the ICP installation, will be used as basename for VMs
variable "instance_name" { default = "myicp" }

# Password to use for default admin user
variable "default_admin_password" { default = "admin" }

##### ICP Instance details ######
variable "master" {
  type = "map"
  default = {
    nodes       = "1"
    cpu_cores   = "2"
    disk_size   = "25" // GB
    local_disk  = false
    memory      = "8192"
    network_speed= "1000"
    private_network_only=false
    hourly_billing=true
  }

}
variable "proxy" {
  type = "map"
  default = {
    nodes       = "1"
    cpu_cores   = "2"
    disk_size   = "25" // GB
    local_disk  = true
    memory      = "8192"
    network_speed= "1000"
    private_network_only=false
    hourly_billing=true
  }

}
variable "worker" {
  type = "map"
  default = {
    nodes       = "2"
    cpu_cores   = "2"
    disk_size   = "25" // GB
    local_disk  = true
    memory      = "8192"
    network_speed= "1000"
    private_network_only=false
    hourly_billing=true
  }

}
