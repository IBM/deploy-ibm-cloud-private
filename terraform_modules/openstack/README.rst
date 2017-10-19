=======
Summary
=======

This Terraform sample will perform a simple IBM Cloud private (ICp) deployment
using the Community Edition. It is currently setup to deploy an ICp master node
(also serves as the boot and proxy node) and a user-configurable number of ICp
worker nodes. This sample does not supersede the official ICp deployment
instructions, it merely serves as a simple way to provision an ICp cluster
atop your OpenStack-based infrastructure for experimental purposes.

Assumptions
-----------
* It is assumed that the reader is already familiar with IBM Cloud private;
  if you are not, please refer to the `ICp Community
  <https://www.ibm.com/developerworks/community/wikis/home?lang=en#!/wiki/W1559b1be149d_43b0_881e_9783f38faaff>`_

Prerequisites
-------------
* You have `downloaded Terraform
  <https://www.terraform.io/downloads.html>`_ and installed it on your workstation
* You have an installation of OpenStack (or PowerVC) up and running; this
  module has been confirmed to work on Ocata-based OpenStack deployments
* You have an Ubuntu 16.04 image loaded within your OpenStack (or PowerVC)
  environment; this will be used as the baseline virtual machine for all of the
  ICp nodes

Instructions
------------
* Download (i.e., **git clone**) all of the files in this module and place them
  in an ICp directory on your Terraform workstation
* On your Terraform workstation, generate an SSH key pair to be pushed (via
  Terraform) to all of the nodes; e.g., you can [**ssh-keygen -t rsa**] to
  create this from a Linux or macOS workstation (this will be referenced in
  the subsequent step when you're updating **variables.tf**)
* Edit the contents of **variables.tf** to align with your OpenStack (or
  PowerVC) deployment (make sure you're using an OpenStack flavor with
  sufficient resources; a minimum of 2 vcpus and 8 GB of memory is recommended)
* Within **bootstrap_icp_master.sh**, change the *ICP_DOCKER_IMAGE*
  (*ibmcom/cfc-installer* for x86 or *ppc64le/cfc-installer* for Power Systems)
  and *ICP_VER* variables to align with your desired ICp architecture and version
* Within **ibm-icp-deploy.tf**, change the value of the "count" variable to the
  number of ICp worker nodes that you want to deploy; note that if you're
  using this for anything beyond a proof-of-concept, please also take the
  added step of setting *insecure=false* and set the *cacert* option as
  appropriate for your OpenStack infrastructure
* Run [**terraform apply -parallelism=2**] to start the ICp deployment
* Sit back and relax... within about 20-30 minutes, you should be able to
  access your ICp cluster at https://<ICP_MASTER_IP_ADDRESS>:8443
