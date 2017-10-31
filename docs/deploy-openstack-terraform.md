Summary
=======

This Terraform sample will perform a simple IBM Cloud Private (ICP) deployment.
By default, it will install the Community Edition, but you can also configure
it to install the Enterprise Edition as well. It is currently setup to deploy
an ICP master node (also serves as the boot, proxy, and management node) and a
user-configurable number of ICP worker nodes. This sample does not supersede
the official ICP deployment instructions (as of version 2.1.0), it merely serves
as a simple way to provision an ICP cluster within your infrastructure.

Assumptions
-----------
* It is assumed that the reader is already familiar with IBM Cloud Private;
  if you are not, please refer to the `ICP Community
  <https://www.ibm.com/developerworks/community/wikis/home?lang=en#!/wiki/W1559b1be149d_43b0_881e_9783f38faaff>`_
* It is assumed that the reader is already familiar with Terraform; if you
  are not, there are a lot of great articles available on the web

Prerequisites
-------------
* You have `downloaded Terraform
  <https://www.terraform.io/downloads.html>`_ and installed it on your workstation
* You have an instance of OpenStack (or PowerVC) running; the OpenStack version
  should be Ocata or newer
* You have an Ubuntu 16.04 image loaded within OpenStack with minimally a
  **100 GB root disk**; this will be used as the baseline image for all of the
  ICP nodes

Instructions
------------
* Clone (**git clone git@github.com:IBM/deploy-ibm-cloud-private.git**)
  this repository so you have these files on your Terraform workstation
* On your Terraform workstation, generate an SSH key pair to be pushed (via
  Terraform) to all of the nodes; e.g., you can [**ssh-keygen -t rsa**] to
  create this from a Linux or macOS workstation (this will be referenced in
  the subsequent step when you're updating **variables.tf**).
* Your Ubuntu image should have a default user (often `ubuntu`) that has
  sudo (root) access in order to provision the install (configured via
  **variables.tf**).
* Edit the contents of **variables.tf** to align with your OpenStack
  (or PowerVC) deployment (make sure you're using an OpenStack flavor with
  sufficient resources; a minimum of 4 vcpus and 16 GB of memory is recommended)
* If you want to install ICP Enterprise Edition, you need to:

  * Place the ICP tar ball in an HTTP(S) accessible location (i.e., so that
    wget can be used to download the file)
  * Update the *icp_architecture*, *icp_edition*, and *icp_download_location*
    variables within the **variables.tf** file to point to appropriate ICP
    architecture, edition, and tar ball.
* Run [**terraform apply**] to start the ICP deployment
* Sit back and relax... within about 30-40 minutes, you should be able to
  access your ICP cluster at https://<ICP_MASTER_IP_ADDRESS>:8443
* If you're using this for anything beyond a proof-of-concept, please also take
  the added step of setting the **insecure=false** variable in the **main.tf**
  openstack provider, and the OS_CACERT environment variable.
  (https://www.terraform.io/docs/providers/openstack/#ca_certfile)

See [Accessing IBM Cloud Private](/README.md#accessing-ibm-cloud-private) for next steps.
