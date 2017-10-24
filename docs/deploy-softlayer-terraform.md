## Deploy IBM Cloud Private beta to IBM Cloud (softlayer) with Terraform

### Requirements

* [Terraform](https://www.terraform.io/downloads.html)
* [Softlayer module for Terraform](https://github.com/softlayer/terraform-provider-softlayer#install)
* [Softlayer API Key](https://knowledgelayer.softlayer.com/procedure/retrieve-your-api-key)

### Deploy

Open [terraform/ibmcloud/variables.tf](../terraform/ibmcloud/variables.tf) in your preferred text
editor and update the following variables to suit your environment:

* sl_username
* sl_api_key
* key_name
* key_file
* datacenter

_Make sure the private key that matches your `key_name` is added to your ssh-agent._

Initialize Terraform:

```bash
$ cd terraform/ibmcloud
$ terraform init
Downloading modules...
Get: git::https://github.com/ibm-cloud-architecture/terraform-module-icp-deploy.git

Initializing provider plugins...
- Checking for available provider plugins on https://releases.hashicorp.com...
- Downloading plugin for provider "null" (1.0.0)...
- Downloading plugin for provider "tls" (1.0.0)...

Initializing provider plugins...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.null: version = "~> 1.0"
* provider.tls: version = "~> 1.0"

Terraform has been successfully initialized!
```

_Note: If you see the following error `Error retrieving SSH key: SOAP-ENV:Client: Bad Request (HTTP 200)` comment out the line
beginning with `endpoint_url` from `~/.softlayer`._

Next start the ICP deploy / install:

```
$ terraform apply -parallelism=2
data.softlayer_ssh_key.public_key: Refreshing state...
softlayer_virtual_guest.icpmaster: Creating...
...
...
module.icpprovision.null_resource.icp-boot (remote-exec): PLAY RECAP *********************************************************************
module.icpprovision.null_resource.icp-boot (remote-exec): 169.47.232.XXX             : ok=172  changed=66   unreachable=0    failed=0
module.icpprovision.null_resource.icp-boot (remote-exec): 169.60.192.XXX             : ok=146  changed=47   unreachable=0    failed=0
module.icpprovision.null_resource.icp-boot (remote-exec): 169.60.192.XXX             : ok=118  changed=47   unreachable=0    failed=0
module.icpprovision.null_resource.icp-boot (remote-exec): 169.60.192.XXX             : ok=118  changed=47   unreachable=0    failed=0
module.icpprovision.null_resource.icp-boot (remote-exec): localhost                  : ok=216  changed=114  unreachable=0    failed=0
module.icpprovision.null_resource.icp-boot (remote-exec): POST DEPLOY MESSAGE ************************************************************
module.icpprovision.null_resource.icp-boot (remote-exec): UI URL is https://169.47.232.XXX:8443 , default username/password is admin/admin
module.icpprovision.null_resource.icp-boot (remote-exec): Playbook run took 0 days, 0 hours, 26 minutes, 13 seconds
```

wait a few minutes then check you can access the provided URL from above. If it fails you may just need to wait a while longer for it to come online.

See [Accessing IBM Cloud Private](/README.md#accessing-ibm-cloud-private) for next steps.
