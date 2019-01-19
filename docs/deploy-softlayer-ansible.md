## Deploy IBM Cloud Private beta on IBM Cloud (softlayer) with Ansible

### Before you start...

The following Ansible playbooks will be used for deploying your VM's on SoftLayer:

|                       Playbook                        |                                                     Description                                                     |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| [create_sl_vms.yml](../playbooks/create_sl_vms.yml)   | Create the VM's on SoftLayer according to the specifications found on [cluster/config.yaml](../cluster/config.yaml) |
| [prepare_sl_vms.yml](../playbooks/prepare_sl_vms.yml) | Install all operating system packages required to for the ICP install.                                              |

To customize the hardware definitions of the VM's you'll need to update your local copy of the provisioning playbooks, for instance if an additional disk or more CPU is required.

Please notice that Primary disk sizes should go from 25 GB to 100 GB, if more space is required an additional disk should be created, its also important to notice that disk sizes must have the same size as defined at the default templates provided by the SoftLayer catalog or else your provisioning will fail. Check the documentation below for reference on default sizes available.
 
 - [IBM Block Storage: Provisioning Considerations](https://console.bluemix.net/docs/infrastructure/BlockStorage/index.html#provisioning-with-performance)

For a complete reference on the available arguments, check the following links:

- [IBM Cloud Infrastructure (SoftLayer) API docs](http://sldn.softlayer.com/reference/services/SoftLayer_Virtual_Guest)
- [IBM Cloud Provider (Argument Reference)](https://ibm-cloud.github.io/tf-ibm-docs/v0.11.1/r/compute_vm_instance.html)


### Prepare your local machine:

The first thing you need to do is to clone this repo down and set up to use softlayer cli and ansible:

```bash
git clone https://github.com/IBM/deploy-ibm-cloud-private.git
cd deploy-ibm-cloud-private
sudo pip install -r requirements.txt
```

Next you need to prepare the softlayer CLI with your credentials:

```bash
slcli config setup
Username: XXXXXX
API Key or Password: XXXXXXXXXXXXXXXXXXXXX
Endpoint (public|private|custom) [public]:
Timeout [0]:
:..............:..................................................................:
:         name : value                                                            :
:..............:..................................................................:
:     Username : XXXXXX                                                           :
:      API Key : XXXXXXXXXXXXXXXXXXXXX                                            :
: Endpoint URL : https://api.softlayer.com/xmlrpc/v3.1/                           :
:      Timeout : not set                                                          :
:..............:..................................................................:
Are you sure you want to write settings to "/home/XXXX/.softlayer"? [Y/n]: Y
```

Create a SSH key to use:

```bash
ssh-keygen -f cluster/ssh_key -P ""
Generating public/private rsa key pair.
Overwrite (y/n)? y
Your identification has been saved in cluster/ssh_key
Your public key has been saved in cluster/ssh_key.pub
$ slcli sshkey add -f cluster/ssh_key.pub icp-key
$ slcli sshkey list               
:........:....................:.................................................:.......:
:   id   :       label        :                   fingerprint                   : notes :
:........:....................:.................................................:.......:
: 926125 :    icp-key     : 2c:ba:f4:8d:0c:4f:35:3d:fb:98:0b:30:b3:2e:a4:09 :   -   :
:........:....................:.................................................:.......:
```

> Set the `sl_ssh_key` variable in `clusters/config.yaml` with the id
  from the output of the `slcli sshkey list` command.

Pick a datacenter and a VLAN to deploy to:

```
slcli vlan list
:.........:........:......:..........:............:..........:.................:............:
:    id   : number : name : firewall : datacenter : hardware : virtual_servers : public_ips :
:.........:........:......:..........:............:..........:.................:............:
: 2073387 :  866   :  -   :    No    :   dal09    :    0     :        1        :     61     :
: 2073385 :  812   :  -   :    No    :   dal09    :    0     :        1        :     13     :
```

> Set the `sl_datacenter` and `sl_vlan` variables in `clusters/config.yaml`
  using the datacenter name (ex dal09) and vlan id (ex 2073387). Unless you're very familiar
  with your softlayer account you may need to use the softlayer
  web portal to pick a VLAN to use.  If you skip this step SL will pick a random vlan and you
  may not be able to communicate on the backend network.

### Provision the Softlayer VMs

Using ansible playbooks we've prepared you can create the VMs necessary to deploy ICP:

_While the playbook runs fast, it can take some time for the systems to actually come online and be ready._

```bash
$ ansible-playbook playbooks/create_sl_vms.yml
PLAY [create servers] ****************************************************************************************************************************************************************

TASK [Include cluster vars] **********************************************************************************************************************************************************
ok: [localhost]

TASK [create master] *****************************************************************************************************************************************************************
changed: [localhost] => (item=icp-master01)

TASK [create workers] ****************************************************************************************************************************************************************
changed: [localhost] => (item=icp-worker01)
changed: [localhost] => (item=icp-worker02)

PLAY RECAP ***************************************************************************************************************************************************************************
localhost                  : ok=3    changed=2    unreachable=0    failed=0   
```

Once the systems are online you should be able to prepare them for the ICP install using the following
Ansible playbook. This playbook will clean up some Softlayer quirks, install Docker and slipstream the
softlayer dynamic inventory dependencies into the ICP installer.

```bash
ssh-add cluster/ssh_key
ansible-playbook -i hosts playbooks/prepare_sl_vms.yml

PLAY [ensure connectivity to all nodes] **********************************************************************************************************************************************

TASK [check if python is installed] **************************************************************************************************************************************************
ok: [169.46.198.209]
ok: [169.46.198.195]
ok: [169.46.198.216]
...
...
TASK [Run the following command to deploy IBM Cloud Private] *************************************************************************************************************************
ok: [169.46.198.212] => {
    "msg": "ssh root@169.46.198.212 docker run -e SL_USERNAME=<SL_USERNAME> -e SL_API_KEY=<SL_API_KEY> -e LICENSE=accept --net=host --rm -t -v /root/cluster:/installer/cluster icp-on-sl install"
}
PLAY RECAP ***************************************************************************************************************************************************************************
169.46.198.195             : ok=8    changed=6    unreachable=0    failed=0   
169.46.198.209             : ok=8    changed=6    unreachable=0    failed=0   
169.46.198.216             : ok=8    changed=6    unreachable=0    failed=0   
```

_Note: Sometimes this last task will error due to a strange dnsmasq issue. Running the playbook again usually fixes it, sometimes you need to restart dnsmasq (again) on the master node._

Once that playbook has finished running we can use our modified deployer to deploy ICP (the final line in the previous command will give you the command syntax, you just need to plug in your SL credentials)

```bash
cat ~/.softlayer
[softlayer]
username = XXXXX
api_key = YYYY
$ ssh root@169.46.198.216 docker run -e SL_USERNAME=XXXXX -e SL_API_KEY=YYYY -e LICENSE=accept --net=host \
   --rm -t -v /root/cluster:/installer/cluster icp-on-sl install
...
...
PLAY RECAP *********************************************************************
169.46.198.XXX             : ok=44   changed=22   unreachable=0    failed=0   
169.46.198.YYY             : ok=69   changed=39   unreachable=0    failed=0   
169.46.198.ZZZ             : ok=45   changed=22   unreachable=0    failed=0   


POST DEPLOY MESSAGE ************************************************************

UI URL is https://169.46.198.XXX:8443 , default username/password is admin/admin

```
See [Accessing IBM Cloud Private](/README.md#accessing-ibm-cloud-private) for next steps.
