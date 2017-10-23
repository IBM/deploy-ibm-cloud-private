=======
Summary
=======

This Terraform sample will perform a simple IBM Cloud Private (ICP) deployment.
By default, it will install the Community Edition, but you can also configure
it to install the Enterprise Edition as well. It is currently setup to deploy
an ICP master node (also serves as the boot and proxy node) and a
user-configurable number of ICP worker nodes. This sample does not supersede
the official ICP deployment instructions, it merely serves as a simple way to
provision an ICP cluster within your infrastructure for experimental purposes.

Assumptions
-----------
* It is assumed that the reader is already familiar with IBM Cloud private;
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
  **120 GB root disk**; this will be used as the baseline image for all of the
  ICP nodes

Instructions
------------
* Clone (**git clone git@github.com:IBM/deploy-ibm-cloud-private.git**)
  this repository so you have these files on your Terraform workstation
* On your Terraform workstation, generate an SSH key pair to be pushed (via
  Terraform) to all of the nodes; e.g., you can [**ssh-keygen -t rsa**] to
  create this from a Linux or macOS workstation (this will be referenced in
  the subsequent step when you're updating **variables.tf**)
* Edit the contents of **variables.tf** to align with your OpenStack
  (or PowerVC) deployment (make sure you're using an OpenStack flavor with
  sufficient resources; a minimum of 4 vcpus and 16 GB of memory is recommended)
* Within the **bootstrap_icp_(ce|ee)_master.sh** shell script, change the ICP
  version tag to align with whatever release of ICP that you want to deploy
* If you want to install ICP Enterprise Edition, you need to:

  * Place the ICP tar ball in an HTTP(S) accessible location (i.e., so that
    wget can be used to download the file)
  * Change the *icp-master-vm* resource within the **ibm-icp-deploy.tf** file
    to call the **bootstrap_icp_ee_master.sh** shell script
  * Update the *ICP_IMAGE_HTTP_LOCATION* variable within the **bootstrap_icp_ee_master.sh**
    shell script to point to the ICP tar ball
  * Update the *ICP_DOCKER_IMAGE* variable within the **bootstrap_icp_ee_master.sh**
    shell script to refer to the correct Docker image (i.e., x86 vs. ppc64le)
* Run [**terraform apply -parallelism=2**] to start the ICP deployment
* Sit back and relax... within about 30-40 minutes, you should be able to
  access your ICP cluster at https://<ICP_MASTER_IP_ADDRESS>:8443
* If you're using this for anything beyond a proof-of-concept, please also take
  the added step of setting *insecure=false* and set the *cacert* option to the
  contents of the OpenStack certificate
