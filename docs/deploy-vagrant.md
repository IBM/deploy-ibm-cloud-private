## Deploy IBM Cloud Private beta using Vagrant

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

See [Accessing IBM Cloud Private](/README.md#accessing-ibm-cloud-private) for next steps.
