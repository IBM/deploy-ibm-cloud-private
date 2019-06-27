## Deploy IBM Cloud Private on a Nutanix hyperconverged infrastructure with Ansible

This is a collection of sample Ansible playbooks that can be customized and used for quick ICP deployment on a on premises Nutanix cluster. Both x86 and ppc64le (Power) architectures are supported, and both Ubuntu and RHEL OSs are supported.

Supports ICP versions 3.x and above.

### Prepare your Nutanix cluster:

There are 2 small steps you will need to do in order to prepare your Nutanix cluster for deployment:

  - upload a cloud disk image from a supported OS (RHEL or Ubuntu)
  - configure networking in the cluster

If you have already deployed a Nutanix cluster chances are the above tasks were already achieved. If not, you can simply login into the Nutanix PRISM UI and follow the proper procedures as described in their documentation:

  - [Adding an image](https://portal.nutanix.com/#/page/docs/details?targetId=Prism-Central-Guide-Prism-v55:mul-image-add-pc-t.html)
  - [Configuring a virtual network for user VM interfaces](https://portal.nutanix.com/#/page/docs/details?targetId=Web-Console-Guide-Prism-v55:wc-virtual-network-for-user-vm-vnics-configure-wc-t.html)

Once you're done take note of the image name and the network name you'd like to use to deploy your ICP cluster.

### Configure your Nutanix cluster settings

You can find these in the first part of this [file](../nutanix/vars/nutanix.yml). It's a best practice to define different clusters to assume different roles, for example, a "prod" cluster that contains the production deployment and a "test" cluster that contains the test deployment. Each of these clusters have key parameters that will need to be configured:

| variable | example | description |
| ------ | ------ | ------ |
| address | 9.53.168.50 | The IP address of the Nutanix cluster |
| port | 9440 | The port number where the Nutanix API resides, usually 9440 |
| validate_certs | False | Wether to validate the Nutanix server certificate |
| username | admin | A valid user name to interact with the Nutanix cluster |
| password | passw0rd<sup>*</sup> | The password associated to the Nutanix user |

<sup>*</sup>Obs: It's a best practice to always encrypt any secrets before publishing it in an Ansible yml file. The ansible-vault command can be used for this purpose. To make it easier we provide a sample syntax [here](../nutanix/scripts/enc.sh). Use it as:

```sh
cd nutanix
scripts/enc.sh <password_to_encrypt>
```
And then copy the resullting encrypted string into the proper variable in your yml file.

### Configure your Nutanix playbook settings

You can find these in the second part of this [file](../nutanix/vars/nutanix.yml). Here we define key Nutanix-related variables that will need to be configured:

| variable | example | description |
| ------ | ------ | ------ |
| do_debug (optional) | False | For debugging purposes, shows output from remote REST API calls and other debugging messages |
| do_verbose (optional) | False | Extra verbose debugging, usually for development purposes only |
| cluster | "{{ clusters.test }}" | Points to a Nutanix cluster to use for deployment (defined on previous section) |
| vms_root_password | passw0rd<sup>*</sup> | The password to set for the root user in the VMs to be used for ICP installation |
| vms | see [sample](../nutanix/vars/nutanix.yml) | List variable containing multiple Virtual Machine definitions |
| vgs (optional) | see [sample](../nutanix/vars/nutanix-sample.yml) | List variable containing multiple Volume Group definitions |
| map_vm_vg (optional) | see [sample](../nutanix/vars/nutanix-sample.yml) | List variable with entries attaching Volume Groups to Virtual Machines |

<sup>*</sup>Obs: See best practices for encryption of secrets as explained in the previous section.

Each element in the "vms" array corresponds to a VM that will be created in the Nutanix cluster. The following parameters can be set for each VM:

| parameter | example | description |
| ------ | ------ | ------ |
| type | sample | The role this VM will assume in the cluster, e.g. master, worker, proxy, etc. |
| name | a-sample-vm | The hostname to be set for this VM |
| mem | 32768 (32GB)| The amount of memory (in MB) to allocate for this VM |
| cpu | 1 | The number of vCPUs to allocate for this VM |
| cpc | 6 | The number of vCores per vCPU to allocate for this VM |
| net | br.0 | The name of the Nutanix network to use for this VM |
| boot | { img: "ubuntu-cloud-16.04-20180427", size: 128849018880 } | Dictionary with image name and size for the VM boot disk |
| clones (optional) | [ "empty_100gb", ... ] | List of image names to clone as disks for this VM |
| disks (optional) | [ 128849018880 ] | List of size in bytes for new disks to be created for this VM |
| user (optional) | ubuntu | The boot image's pre-configured user Id to use when connecting to it |
| body | vm-create.j2 | The default VM body template to use when creating the VM (includes cloud-init configuration) |

Each element in the "vgs" array corresponds to a VG that will be created in the Nutanix cluster. The following parameters can be set for each VG:

| parameter | example | description |
| ------ | ------ | ------ |
| name | a-sample-vm | The hostname to be set for this VM |
| container | default-container | The name of the storage container to use for this VG |
| shared | "true" | Use "true" if you want to share this VG among multiple VMs, "false" otherwise |
| clones (optional if disks is defined) | [ "empty_100gb", ... ] | List of image names to clone as disks for this VG |
| disks (optional if clones is defined) | [ 128849018880 ] | List of size in bytes for new disks to be created for this VG |
| body | vg-create.j2 | The default VG body template to use when creating the VG |

Finally, you can map VGs to VMs by defining a list in the map_vms_vgs variable. Each entry in the list is a VM-VG pair that associates a VM name to a VG name. If you want to map multiple VGs to a VM or vice-versa just define multiple entries. You can see an example of such list of mappings [here](../nutanix/vars/nutanix-sample.yml).

### Configure your ICP installation settings

You can find the ICP installation parameters in this [file](../nutanix/vars/icp.yml). The following are key variables that will need to be configured for a successful ICP installation:

| variable | example | description |
| ------ | ------ | ------ |
| do_debug (optional) | False | For debugging purposes, shows output from commands and debugging messages |
| do_verbose (optional) | False | Extra verbose debugging, usually for development purposes only |
| icp_conf | /opt/icp | Location where the ICP inception installation configuration will reside |
| icp_image_x86<sup>*</sup> (mandatory if installing from or to x86 nodes) | /root/ibm-cloud-private-x86_64-3.1.1.tar.gz | Path of the ICP x86 image compressed tarball |
| icp_image_ppc<sup>*</sup> (mandatory if installing from or to Power nodes) | /root/ibm-cloud-private-ppc64le-3.1.1.tar.gz | Path of the ICP ppc64le image compressed tarball |
| icp_inception_version | 3.1.1-ee | Version of the container image to use for ICP inception (specify ee vs. ce for enterprise or community editions) |
| icp_target_arch | ppc64le | Architecture of target nodes... use "amd64" for x86, "ppc64le" for power |

<sup>*</sup>Obs: It is required that you download the proper ICP images for your platform(s) (either x86 or Power or both) from IBM Passport Advantage and place them in a locally accessible directory prior to running this playbook. The architecture of target nodes doesn't necessarily need to be the same as the installation node you're using. For example, one can run this playbook on a x86 node and install ICP to target Power nodes. The configuration however needs to point to both image architecture tarballs for this to work.

Once all these configuration parameters are set you're ready to initiate your deployment. During deployment the playbook will load the ICP images in the deployment node (system you're running this playbook from), create an ICP configuration pointing to the targets in the Nutanix cluster and then remotely install the ICP cluster in the target VMs.

### Deployment steps

There are 4 steps necessary for deployment, that have to run in sequence:

  - Nutanix [config](../nutanix/nx_config.yml) creates the VMs in the Nutanix cluster
  - Nutanix [deploy](../nutanix/nx_deploy.yml) configures the VMs for deployment
  - ICP [config](../nutanix/icp_config.yml) loads ICP images in the deployer and configures ICP deployment parameters
  - ICP [deploy](../nutanix/icp_deploy.yml) installs ICP on the remote VM nodes

In addition there's 2 teardown steps in case you'd like to clean your environment:

  - Nutanix [teardown](../nutanix/nx_teardown.yml) removes all previously created VMs in the Nutanix cluster
  - ICP [teardown](../nutanix/icp_teardown.yml) removes the ICP images and configuration in the deployer

And for convenience there's also an [install](../nutanix/nx-icp-install.yml) step that runs all 4 main deployment steps in sequence and a respective [uninstall](../nutanix/nx-icp-install.yml) step that runs both teardown steps in sequence.

If you have encrypted secrets you will need to pass the file containing the vault secret to Ansible when running each of these playbooks. To make it easier we provide a sample syntax [here](../nutanix/scripts/run.sh). Use it as:

```sh
cd nutanix
scripts/run.sh <deployment_step_name>
```

### Precaution when using RedHat Enterprise Linux images

To sucessfully use RHEL cloud images users must use the Nutanix [deploy](../nutanix/nx_deploy.yml) step to properly set up the RedHat subscription and register repositories for use with yum. If this step is not done the ICP deployment will fail. There are many ways to achieve this. As an example we use a sample role called "rhel" that makes use of certificate variables define [here](../nutanix/vars/redhat.yml). With these variables our sample tasks [here](../nutanix/roles/rhel/tasks/subscribe.yml) invoke subscription-manager commands to properly register the subscription and sets up repositories for use with yum. If your organization uses an alternate (or legacy) method to set up subscription and repositories please replace these tasks and variables accordingly.

### What to expect during deployment

The full deployment end-to-end takes ~ 1:30h to complete (depending on the number of nodes) with the ICP installation step alone taking ~1:15h. Each of the long-running tasks (ICP load and ICP deploy) are executed asynchronously with a respective polling task is used to wait completion. These polling tasks will display a countdown of "FAILED" messages until the corresponding task it's monitoring completes - this is normal. Once the task completes the polling task should also complete successfully.

Upon playbook completion you can inspect the ICP installation logs in the location defined by the icp_conf variable, under the cluster/logs directory. If all went well you can then login to the ICP UI here: https://<ICP_MASTER_VM_IP_ADDRESS>:8443. The default user id and password is admin / admin.

Happy ICP deployment !!!
