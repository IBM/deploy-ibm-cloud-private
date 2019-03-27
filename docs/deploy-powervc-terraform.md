Summary
=======
This Terraform module will perform a simple IBM Cloud Private (ICP) deployment. By default, it will install the Community Edition, but you can also configure it to install the Enterprise Edition as well. It is currently setup to deploy an ICP master node (also serves as the boot, proxy, and management node) and a user-configurable number of ICP worker nodes. This module serves as a simple way to provision an ICP cluster within your infrastructure.

For provisioning on OpenStack environment please look at [Deploy in Openstack using Terraform](deploy-openstack-terraform.md)

Pre-requisites
------------
* Get access to a PowerVC server instance.
* If the default SSH user is not the root user, the default user must have password-less sudo access.
* Install [Terraform](https://www.terraform.io/downloads.html) on your workstation.
* Refer to ICP documentation for installation pre-requisites. https://www.ibm.com/support/knowledgecenter/en/SSBS6K/product_welcome_cloud_private.html

Supported OS versions
------------
This Terraform deployment supports the following OS images on different platforms. Check ICP documentation for supported system configurations.

    * Ubuntu 18.04 LTS and 16.04 LTS
    * Red Hat Enterprise Linux (RHEL) 7.4, 7.5, and 7.6
    * SUSE Linux Enterprise Server (SLES) 12 SP3
    
Additional image considerations
------------
Ensure that the base image used for deployment have necessary repositories configured to install docker and other packages, or have all the below packages pre-installed.
* docker-ce (docker for SLES) -  ICP Enterprise Edition users should use the ICP-provided platform specific docker tar ball and the docker_download_location variable in variables.tf to specify the download url.
* moreutils
* container-selinux
* socat
* nfs-kernel-server (nfs-utils for RHEL)

Instructions
------------
1. Login to your Terraform workstation.
2. Clone this repository. (git clone git@github.com:IBM/deploy-ibm-cloud-private.git)
3. Run `cd deploy-ibm-cloud-private/terraform/powervc/` to change the directory.
4. Run `ssh-keygen -t rsa` to generate an SSH key pair. This will be referenced in [Inputs](#inputs) below.
5. Pass the [Input](#inputs) variables to align with your OpenStack (or PowerVC) deployment. (see [How To](#how-to) section below)
6. Run `terraform init` to initialize and download the terraform modules needed for deployment.
7. Run `terraform apply` to start the ICP deployment to the OpenStack server.
8. Wait for about 30-40 minutes. You should be able to access your ICP cluster at https://<ICP_MASTER_IP_ADDRESS>:8443

See [Accessing IBM Cloud Private](/README.md#accessing-ibm-cloud-private) for next steps.

[Inputs](#inputs)
------------
**Configure the OpenStack Provider**

| Name | Default | Type | Description |
|--------------------|---------------|--------|----------------------------------------|
|openstack_user_name|my_user_name|string|The user name used to connect to OpenStack|
|openstack_password|my_password|string|The password for the user|
|openstack_project_name|ibm-default|string|The name of the project (a.k.a. tenant) used|
|openstack_domain_name|Default|string|The domain to be used|
|openstack_auth_url|https://<HOSTNAME>:5000/v3/|string|The endpoint URL used to connect to OpenStack|

**Configure the Instance details**

| Name | Default | Type | Description |
|--------------------|---------------|--------|----------------------------------------|
|instance_prefix|icp|string|Prefix to use in instance names|
|openstack_image_id|my_image_id|string|The ID of the image to be used for deploy operations|
|openstack_master_node|{"flavor_id" = "large"}|map|Map of flavor ID to be used for ICP master node deploy operations|
|openstack_worker_node|{<br/> "count" = "1"<br/>"flavor_id" = "large"<br/>}|map|Map of count and flavor ID to be used for ICP worker node deploy operations|
|openstack_management_node|{<br/> "count" = "0"<br/>"flavor_id" = "large"<br/>}|map|Map of count and flavor ID to be used for ICP management node deploy operations|
|openstack_proxy_node|{<br/> "count" = "0"<br/>"flavor_id" = "large"<br/>}|map|Map of count and flavor ID to be used for ICP proxy node deploy operations|
|openstack_va_node|{<br/> "count" = "0"<br/>"flavor_id" = "large"<br/>}|map|Map of count and flavor ID to be used for ICP va node deploy operations|
|openstack_network_name|my_network_name|string|The name of the network to be used for deploy operations|
|openstack_ssh_key_file|<path to the private SSH key file>|string|The path to the private SSH key file. Appending '.pub' indicates the public key filename|


**Configure ICP details**

| Name | Default | Type | Description |
|--------------------|---------------|--------|----------------------------------------|
|icp_install_user|ubuntu|string|The user with sudo access across nodes (users section of cloud-init)|
|icp_install_user_password||string|Password for sudo access (leave empty if using passwordless sudo access)|
|icp_version|3.1.2|string|ICP version number|
|icp_architecture|ppc64le|string|x86 or ppc64le|
|icp_download_location||string|HTTP wget location for ICP Enterprise Edition - ignored for community edition|
|icp_default_admin_password|S3cure-icp-admin-passw0rd-default|string|Password to use for default admin user|
|icp_management_services|{<br/>"istio" = "disabled"<br/> "metering" = "enabled"<br/>}|map|Map of management services to enable/disable in icp config.yaml|
|icp_configuration|{}|map|Map of configuration values for ICP|
|docker_download_location||string|HTTP wget location for ICP provided Docker package|

**Configure MCM details**
This is an optional component to install on top of ICP.
Will enable only if *mcm_download_location* is provided in input variables.

| Name | Default | Type | Description |
|--------------------|---------------|--------|----------------------------------------|
|mcm_download_location||string|HTTP wget location for MCM tarball|
|mcm_download_user|-|string|Optional username if authentication required for MCM tarball|
|mcm_download_password|-|string|Optional password if authentication required for MCM tarball|
|mcm_klusterlet_only|false|string|true if need to install Klusterlet without the Hub cluster(remote)|
|mcm_klusterlet_name|mykluster|string|Name of the Klusterlet. Should be unique to each cluster|
|mcm_namespace|mcm|string|Namespace (unique) on Klusterlet or Hub cluster depending on mcm_klusterlet_only flag|
|mcm_hub_server_url||string|If mcm_klusterlet_only is true then Hub cluster URL|
|mcm_hub_server_token||string|If mcm_klusterlet_only is true then Hub cluster Token|

**Configure CAM common details**
This is an optional component to install on top of ICP.
Will enable if *cam_docker_user* is provided for *Online Installation* OR *cam_download_location* is provided for *Offline Installation* in input variables. *cam_docker_user* should be empty string for *Offline Installation*.

| Name | Default | Type | Description |
|--------------------|---------------|--------|----------------------------------------|
|cam_version|3.1.0|string|Manditory version of Cloud Automation Manager to install|
|cam_product_id||string|Product Id text for Cloud Automation Manager (EE)|
|cam_docker_user||string|Docker Store user name, needs subscription to CAM (see documentation)|
|cam_docker_password||string|Docker Store API key OR password|
|cam_download_location||string|HTTP wget location for CAM tarball|
|cam_download_user|-|string|Optional username if authentication required for CAM tarball|
|cam_download_password|-|string|Optional password if authentication required for CAM tarball|

**Configure SMT level for master node**

| Name | Default | Type | Description |
|--------------------|---------------|--------|----------------------------------------|
|smt_value_master||string|Number of threads per core. Value can be any of: on, off, 1, 2, 4, 8|

[How-To](#how-to)
------------
* **Pass the variables**: There are multiple ways to pass input variables to Terraform module. See [docs](https://www.terraform.io/docs/configuration/variables.html#assigning-values-to-root-module-variables) for more information.
* **Re-install MCM on the cluster**:
<br/>`terraform destroy -target=null_resource.mcm_install`
<br/>`terraform apply`
* **Re-install CAM on the cluster**:
<br/>`terraform destroy -target=null_resource.cam_install`
<br/>`terraform apply`
* **Destroy the cluster without waiting to uninstall MCM & CAM**:
<br/>`terraform taint -module=mcm_install null_resource.mcm_install`
<br/>`terraform taint -module=cam_install null_resource.cam_install`
<br/>`terraform destroy`

[Authors](#authors)
------------
Yussuf Shaikh yussuf@us.ibm.com
