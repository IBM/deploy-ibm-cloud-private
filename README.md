# Deploy IBM Cloud Private beta

Instructions:
* [Deploy in local VMs using Vagrant](#deploy-using-vagrant)
* [Deploy in Softlayer VMs using Ansible](#deploy-on-ibm-cloud-softlayer)
* [Deploy in OpenStack using Terraform](#deploy-using-openstack-and-terraform)


## Deploy using Vagrant:

#### Requirements
In order to successfully run the `Vagrantfile` your laptop will need the following:

 - 4GiB of RAM
   -  8GiB will give better performance  
   -  Change the [`memory`](https://github.com/IBM/deploy-ibm-cloud-private/blob/master/Vagrantfile#L15) setting in the `Vagrantfile`
 - 20GiB of free disk space
 - VirtualBox 5.1.28 [Download](https://www.virtualbox.org/wiki/Downloads)
 - Vagrant 2.0.0 [Download](https://www.vagrantup.com/downloads.html)
 - Operating Systems
   - Mac OSx 10.12.6
   - Windows 10
   - Windows 7
   - Ubuntu 16.04 & 16.10

Once you have [VirtualBox](https://www.virtualbox.org/wiki/Downloads) and [Vagrant](https://www.vagrantup.com/downloads.html) installed, clone this repo and use the Vagrantfile to launch your instance
of [IBM Cloud Private](https://www.ibm.com/cloud-computing/products/ibm-cloud-private/).

```bash
$ git clone https://github.com/IBM/deploy-ibm-cloud-private.git
$ cd deploy-ibm-cloud-private
```

#### IBM Cloud Private Vagrant Commands
**install**: `vagrant up`  
**stop**: `vagrant halt`  
**start**: `vagrant up`  
**uninstall**: `vagrant destroy`  
**login to master node**: `vagrant ssh`  
**suspend**: `vagrant suspend`  
**resume**: `vagrant resume`

##### TL;DR
The included `Vagrantfile` defines a single Ubuntu 16.04 VM. On that VM we install [LXD](https://www.ubuntu.com/containers/lxd) - a pure-container hypervisor that runs unmodified Linux guest operating systems with VM-style operations at incredible speed and density. Utilizing [LXD](https://www.ubuntu.com/containers/lxd) we can create a multi-node cluster all running on a single VM and all accessible from the terminal on your laptop. This makes for a great platform for development, test, learning excersizes, and demos.

Once the `Vagrantfile` has installed and configured [LXD](https://www.ubuntu.com/containers/lxd) and installed all of the IBM Cloud Private community edition prereqs on the VM and all LXD containers defined within, it will begin the process of installing IBM Cloud Private community edition. This process should take about 20-30 mins to complete. Once done you will be able to access the IBM Cloud Private community edition web console here: [https://192.168.27.100:8443](https://192.168.27.100:8443) (assuming you did not have to change the [`base_segment`](https://github.com/IBM/deploy-ibm-cloud-private/blob/master/Vagrantfile#L28) value in the `Vagrantfile` see `Conflicting Network Segments` section below for details)  

This `Vagrantfile` will stand up a single [VirtualBox](https://www.virtualbox.org/wiki/Downloads) VM and deploy the `master` and `proxy` nodes onto it. It will configure and start three additional `lxc` containers within the [VirtualBox](https://www.virtualbox.org/wiki/Downloads) VM and install the `worker` nodes onto two of them (`cfc-worker1` & `cfc-worker2`) and the management services onto the third (`cfc-manager1`). The `cpu` and `memory` allocated in the `Vagrantfile` will be shared by the VM and the `lxc` containers running the `worker` nodes within it. You can check the status of the `lxc` instances by ssh'ing into the VM using `vagrant ssh` and then running the command `lxc list`:  


| NAME        | STATE   | IPV4                           | IPV6 | TYPE       | SNAPSHOTS |  
| ----------- | ------- | ------------------------------ | ---- | ---------- | --------- |
| cfc-worker1 | RUNNING | 192.168.27.101 (eth0) 172.17.0.1 (docker0) 10.1.213.128 (tunl0)|      | PERSISTENT | 0         |   
| cfc-worker2 | RUNNING | 192.168.27.102 (eth0) 172.17.0.1 (docker0) 10.1.54.64 (tunl0)  |      | PERSISTENT | 0         |  
| cfc-manager1 | RUNNING | 192.168.27.111 (eth0) 172.17.0.1 (docker0) 10.1.16.98 (tunl0)  |      | PERSISTENT | 0         |  

#### Conflicting Network Segments
If you see the addresses `192.168.56.101` or `192.168.56.102` for either `cfc-worker1` or `cfc-worker2` that means there was a conflicting network segment for the `192.168.27.x` network on your system. You will need to change the `base_segment` value in the `Vagrantfile` to a value that will not overlap any existing segments on your machine. See the comments in the `Vagrantfile` for [examples](https://github.com/IBM/deploy-ibm-cloud-private/blob/master/Vagrantfile#L24-L28)

#### Web/Kube Dashboard Showing 3X Amount of Memory/CPU than I have on My Laptop
Because we are using `lxc` containers to run the `cfc-worker1` and `cfc-worker2` nodes you will see the IBM Cloud Private community edition Dashboard report 3x as much memory availble in your cluster than you allocated via the [`memory`](https://github.com/IBM/deploy-ibm-cloud-private/blob/master/Vagrantfile#L15) setting in the `Vagrantfile`. Don't worry, this is normal.  `LXD` is sharing the total memory available to the VirtualBox VM with each `lxc` instance so the amount of memory you see being reported in the IBM Cloud Private community edition console is a result of each node reporting that it has the amount of `memory` allocated to the VirtualBox host in the `memory` setting. The best way to think about how `lxc` instances share host resources is to think of `lxc` instances as being applications that run on your laptop where each `lxc` instance is an application and the host where the `lxc` instances are running is the laptop. Each `lxc` instance can request memory or cpu from the host as needed and return those resources when they are no longer needed just like running multiple applications on your laptop does.

#### Web Terminal
For those of you running vagrant on windows, without access to a true terminal, we have included shellinabox to make accessing the terminal console of the VM easier. Just point your browser to [https://192.168.27.100:4200](https://192.168.27.100:4200) and login with username/password `vagrant`/`vagrant`.

#### Advanced Cache Setup  
If you find yourself running this Vagrant setup multiple times it might be a good idea to setup a _pass-through_ proxy cache server for both the `apt-get` package installs as well as the `docker pull` calls. We've made it easy for you to setup a cache server.  In the same directory as the `Vagrantfile` there is a file called `Cachefile`.  The `Cachefile` is another Vagrant file that is configured to stand up an _apt-cacher-ng_ server as well as a _docker registry_ server. You can run it with:  

```  
export  VAGRANT_VAGRANTFILE=Cachefile  
vagrant up
```  
Both servers act as simple _proxy pass-through_ servers. When you configure the `Vagrantfile` to `use_cache = 'true'` and set the `cache_host = '192.168.27.99'` (which is the default value set in the `Vagrantfile`) all `apt-get install` and `docker pull` commands will proxy through the cache server and use the resources allready cached there or continue on to the original source and cache the result on the cache server. Using the cache server will significantly decrease the amount of time it takes to install ICP on subsequent installs.  

If you want to run the cache server on another machine you will need to identify the IP of the host where you're running the cache server instance and use that value in the `cache_host` property in the `Vagrantfile`.  By default the `Cachefile` will port-forward all requests on the host for `3142` & `5000` onto the vagrant instance of cache server running on the host.  

To persist the cache between restarts **DON'T DESTROY THE CACHE VAGRANT INSTANCE**.  
To stop the cache server run the following:  

```  
export  VAGRANT_VAGRANTFILE=Cachefile  
vagrant halt
```  
To start the cache server up again run the following:  

```  
export  VAGRANT_VAGRANTFILE=Cachefile  
vagrant up
```  

## Deploy on IBM Cloud (softlayer)

### Prepare your local machine:


The first thing you need to do is to clone this repo down and set up to use softlayer cli and ansible:

```bash
$ git clone https://github.com/IBM/deploy-ibm-cloud-private.git
$ cd deploy-ibm-cloud-private
$ sudo pip install -r requirements.txt
```

Next you need to prepare the softlayer CLI with your credentials:

```bash
$ slcli config setup
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
$ ssh-keygen -f cluster/ssh_key -P ""
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
$ ssh-add cluster/ssh_key
$ ansible-playbook -i hosts playbooks/prepare_sl_vms.yml

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


Once that playbook has finished running we can use our modified deployer to deploy ICP (the final line in the previous command will give you the command syntax, you just need to plug in your SL credentials)

```bash
$ cat ~/.softlayer
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
## Accessing IBM Cloud Private

Access the URL using the username, password provided in last few lines of the ICP deployment

![ICP Login Page](images/icp-login-page.png)

Click on `admin` on the top right hand corner of the screen to bring up a menu and select "Configure Client".

![ICP Configure Client](images/icp-configure-client.png)

Copy and Paste the provided commands into a shell:

```bash
kubectl config set-cluster cfc --server=https://169.46.198.216:8001 --insecure-skip-tls-verify=true
kubectl config set-context cfc --cluster=cfc
kubectl config set-credentials user --token=eyJhbGciOiJSUzI1NiIsImtpZCI6IjY5NjI2ZDJkNjM2NjYzMmQ3MzY1NzI3NjY5NjM2NTJkNmI2NTc5NjkiLCJ0eXAiOiJKV1QifQ.eyJhdWQiOiJjZmMtc2VydmljZSIsImV4cCI6MTUwNTc5MTMwOCwiaWF0IjoxNTA1NzQ4MTA4LCJpc3MiOiJodHRwczovL21hc3Rlci5jZmM6ODQ0My9hY3MvYXBpL3YxL2F1dGgiLCJwcm9qZWN0cyI6WyJkZWZhdWx0Il0sInN1YiI6ImFkbWluIn0.wnjScyVuUUJyqt7AW4J6PrZ135dp8nWQTUmAqcjja15vaY4GQsu2lpZTn6AhmzQNWYfaYcLwc1ApcRBAB3h9oQlJOpSMI96U9XDYcMi1_i1AX8zN1EAFnklURK6TKPMy2OfNx8KOoWHTtRqBm-NDcla25aCpIrdHi7P9OPB2dcrHv7cYLBNwB6zWnzkM1EnRXYQIXDtKs1iX1K-A5Ph0Si3LIUg3LOjNML3Yn2D7vCWdItaGs86EE-2R2VVkYsLO19G09KwcLnhf5CmxxTjPDp2dOQjfwIFWbTmVQCFORtqj2Gt3X2EQFBwSru-e9M-fYcUiv6bqpd7WLufo-7q3bg
kubectl config set-context cfc --user=user --namespace=default
kubectl config use-context cfc
```

Check that you can run some basic commands against the cluster:

```bash
$ Client Version: version.Info{Major:"1", Minor:"6", GitVersion:"v1.6.4", GitCommit:"d6f433224538d4f9ca2f7ae19b252e6fcb66a3ae", GitTreeState:"clean", BuildDate:"2017-05-19T18:44:27Z", GoVersion:"go1.7.5", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"5", GitVersion:"v1.5.2", GitCommit:"08e099554f3c31f6e6f07b448ab3ed78d0520507", GitTreeState:"clean", BuildDate:"2017-02-05T08:03:16Z", GoVersion:"go1.7.5", Compiler:"gc", Platform:"linux/amd64"}
$ kubectl get nodes
NAME             STATUS                     AGE       VERSION
169.46.198.195   Ready                      34m       v1.7.3-7+154699da4767fd
169.46.198.209   Ready                      34m       v1.7.3-7+154699da4767fd
169.46.198.216   Ready,SchedulingDisabled   36m       v1.7.3-7+154699da4767fd
```

From here you should be able to interact with ICP via either the Web UI or the `kubectl` command.

## deploy-using-openstack-and-terraform

Please refer to the embedded README document in *terraform_modules/openstack*
for detailed deployment steps.
