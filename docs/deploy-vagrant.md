## Deploy IBM Cloud Private using Vagrant

#### Requirements
In order to successfully run the `Vagrantfile` your laptop will need the following:

 - 6GiB of RAM
   -  8-10GiB of RAM total on your laptop will be required (for other OS processes)
   -  Change the [`memory`](https://github.com/IBM/deploy-ibm-cloud-private/blob/master/Vagrantfile#L15) setting in the `Vagrantfile` 
   -  Can attempt with less memory but no guarantees
 - 100GB of free disk space
 - VirtualBox 5.2.20 r125813 [Download](https://www.virtualbox.org/wiki/Downloads)
 - Vagrant 2.2.x [Download](https://www.vagrantup.com/downloads.html)
 - Operating Systems
   - Mac OSx 10.13.6
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
The included `Vagrantfile` defines a single Ubuntu 16.04 VM. On that VM we install [LXD](https://www.ubuntu.com/containers/lxd) - a pure-container hypervisor that runs unmodified Linux guest operating systems with VM-style operations at incredible speed and density. Utilizing [LXD](https://www.ubuntu.com/containers/lxd) we can create a multi-node cluster all running on a single VM and all accessible from the terminal on your laptop. This makes for a great platform for development, test, learning exercises, and demos.

Once the `Vagrantfile` has installed and configured [LXD](https://www.ubuntu.com/containers/lxd) and installed all of the IBM Cloud Private community edition prereqs on the VM and all LXD containers defined within, it will begin the process of installing IBM Cloud Private community edition. This process should take about 20-30 mins to complete. Once done you will be able to access the IBM Cloud Private community edition web console here: [https://192.168.27.100:8443](https://192.168.27.100:8443) (assuming you did not have to change the [`base_segment`](https://github.com/IBM/deploy-ibm-cloud-private/blob/master/Vagrantfile#L28) value in the `Vagrantfile` see `Conflicting Network Segments` section below for details)  

This `Vagrantfile` will stand up a single [VirtualBox](https://www.virtualbox.org/wiki/Downloads) VM and deploy the `master` and `proxy` nodes onto it. It will configure and start three additional `lxc` containers within the [VirtualBox](https://www.virtualbox.org/wiki/Downloads) VM and install the `worker` nodes onto two of them (`cfc-worker1` & `cfc-worker2`) and the management services onto the third (`cfc-manager1`). The `cpu` and `memory` allocated in the `Vagrantfile` will be shared by the VM and the `lxc` containers running the `worker` nodes within it. You can check the status of the `lxc` instances by ssh'ing into the VM using `vagrant ssh` and then running the command `lxc list`:  


| NAME        | STATE   | IPV4                           | IPV6 | TYPE       | SNAPSHOTS |  
| ----------- | ------- | ------------------------------ | ---- | ---------- | --------- |
| cfc-worker1 | RUNNING | 192.168.27.101 (eth0) 172.17.0.1 (docker0) 10.1.213.128 (tunl0)|      | PERSISTENT | 0         |   
| cfc-worker2 | RUNNING | 192.168.27.102 (eth0) 172.17.0.1 (docker0) 10.1.54.64 (tunl0)  |      | PERSISTENT | 0         |  

#### Conflicting Network Segments
If you see the addresses `192.168.56.101` or `192.168.56.102` for either `cfc-worker1` or `cfc-worker2` that means there was a conflicting network segment for the `192.168.27.x` network on your system. You will need to change the `base_segment` value in the `Vagrantfile` to a value that will not overlap any existing segments on your machine. See the comments in the `Vagrantfile` for [examples](https://github.com/IBM/deploy-ibm-cloud-private/blob/master/Vagrantfile#L24-L28)  Note that after changing `Vagrantfile` `base_segment` value you will need to halt and restart as follows:

    vagrant destroy
    vagrant up

#### Web/Kube Dashboard Showing 3X Amount of Memory/CPU than I have on My Laptop
Because we are using `lxc` containers to run the `cfc-worker1` and `cfc-worker2` nodes you will see the IBM Cloud Private community edition Dashboard report 3x as much memory availble in your cluster than you allocated via the [`memory`](https://github.com/IBM/deploy-ibm-cloud-private/blob/master/Vagrantfile#L15) setting in the `Vagrantfile`. Don't worry, this is normal.  `LXD` is sharing the total memory available to the VirtualBox VM with each `lxc` instance so the amount of memory you see being reported in the IBM Cloud Private community edition console is a result of each node reporting that it has the amount of `memory` allocated to the VirtualBox host in the `memory` setting. The best way to think about how `lxc` instances share host resources is to think of `lxc` instances as being applications that run on your laptop where each `lxc` instance is an application and the host where the `lxc` instances are running is the laptop. Each `lxc` instance can request memory or cpu from the host as needed and return those resources when they are no longer needed just like running multiple applications on your laptop does.

#### Web Terminal
For those of you running vagrant on windows, without access to a true terminal, we have included shellinabox to make accessing the terminal console of the VM easier. Just point your browser to [https://192.168.27.100:4200](https://192.168.27.100:4200) and login with username/password `vagrant`/`vagrant`. 

See [Accessing IBM Cloud Private](/README.md#accessing-ibm-cloud-private) for next steps.
