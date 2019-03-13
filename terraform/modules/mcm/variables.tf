variable "icp_status" {
    default = ""
}

variable "icp_master" {
    default = ""
}

variable "ssh_user" {
    default = "root"
}

variable "ssh_key_base64" {
    default = ""
}

variable "ssh_agent" {
    default = "false"
}

variable "bastion_host" {
    default = ""
}

variable "icp_version" {
    default = ""
}

variable "cluster_name" {
    default = ""
}

variable "icp_admin_user" {
    default = ""
}

variable "icp_admin_user_password" {
    default = ""
}

variable "mcm_secret" {
    default = ""
}

variable "mcm_namespace" {
    default = ""
}

variable "mcm_cluster_namespace" {
    default = ""
}

variable "mcm_download_location" {
    default = ""
}

variable "mcm_download_user" {
    default = "-"
}

variable "mcm_download_password" {
    default = "-"
}
