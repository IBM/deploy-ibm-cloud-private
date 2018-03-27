## Deploy IBM Cloud Private beta to IBM Cloud (softlayer) with Terraform

### Requirements

* [Terraform](https://www.terraform.io/downloads.html)
* [Softlayer module for Terraform](https://github.com/softlayer/terraform-provider-softlayer#install)
* [Softlayer API Key](https://knowledgelayer.softlayer.com/procedure/retrieve-your-api-key)

### Deploy

You will need to collect some information from the Softlayer admin page before you can proceeed. Here's how to get those details:

_Softlayer username and API key_

* Go to the [Softlayer Control page](https://control.softlayer.com/)
* Look at the top right and note which account you're logged in as.  You may have more than one account. IBMers will likely have at least a default personal account and an account from their organization. Pick one that has rights to provision capacity in Softlayer.
* Now go [edit your user profile](https://control.softlayer.com/account/user/profile).
* Scroll down to the bottom and look for the section _API Access Information_
* You will have an "API Username" "Authentication key". The "API Username" will be something like 9999999_shortname@us.ibm.com.
* Copy both of these values into a local text file.  You will need them when you configure the Terraform script.  If you don't have an authentication key, [follow these instructions](https://knowledgelayer.softlayer.com/procedure/generate-api-key)
* Next, go look at your [devices in Softlayer](https://control.softlayer.com/devices)
* Pick a device and look at the details.
* Halfway down the list of details, you will see the _Network_ section in two columns. The public subnet VLAN is on the left, the private subnet VLAN is on the right.
* The subnet will have a name like `wdc01.fcr05a.918`. The first substring identifies the data center. In this case it's data center 01 in Washington DC. Take note of that data center identifier and store it in the same place where you put you Softlayer user ID and API key.
* Next, click on the _public_ VLAN link.  You'll go to a page such as [https://control.softlayer.com/network/vlans/2262109](https://control.softlayer.com/network/vlans/2262109)
* That long number at the end of the URL is the public VLAN ID. Record that number.
* Click the Back button on your browser to get back to the device summary page.
* Click on the _private_ VLAN link and perform the same data collection.
* Record the ID of the private VLAN
* You should now have your Softlayer user ID, API key, data center ID, public VLAN ID, and private VLAN ID.
* You're done with the Softlayer admin page. Go ahead and close the browser.

_SSH Keys_

* Go back to the a command line and change directory to where you cloned the git repository.
* The root of the git repo is `deploy-ibm-cloud-private`. From there, cd to `terraform/ibmcloud`
* Now you will create an ssh key pair and register it with Softlayer.
* The name you give the key in Softlayer has to be unique. This can be tricky if you are using a shared account.  You can't just call it `ssh-key`.
* For now, use your IBM shortname to make the key ID unique. For the following steps, replace _shortname_ with your own actual shortname.
* On the command line, enter
```bash
ssh-keygen -f shortname_ssh_key -P ""
```

* You will end up with two files in the current directory, `shortname_ssh_key` (the private key) and `shortname_ssh_key.pub` (the public key)
* Next, you'll register the public key with Softlayer by executing
```bash
slcli sshkey add -f shortname_ssh_key.pub shortname_ssh_key
```

* Assuming you're successful, you should see a message saying `SSH key added` followed by the hex signature.
* Finally, you will take all of the above information and put it into the `variables.tf` file. Populate the fields as per this table:

variable name | data
--------------|-------------
sl_username |  API Username
sl_api_key | Authentication key
key_name  | shortname_ssh_key
key_file | full path to the private key file
datacenter  | data center ID, e.g. wdc01
public_vlan_id | 7-digit public VLAN ID
private_vlan_id | 7-digit public VLAN ID

* Save your changes to variables.tf and proceed.

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
