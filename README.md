# Deploy IBM Cloud Private

Instructions:

* [Deploy in local VMs using Vagrant](docs/deploy-vagrant.md)
* [Deploy in Softlayer VMs using Ansible](docs/deploy-softlayer-ansible.md)
* [Deploy in Softlayer VMs using Terraform](docs/deploy-softlayer-terraform.md)
* [Deploy in OpenStack using Terraform](docs/deploy-openstack-terraform.md)
* [Optional - add NFS dynamic provsioner to your cluster](docs/deploy-nfs-provisioner.md)


## Accessing IBM Cloud Private

Access the URL using the username, password provided in last few lines of the ICP deployment.

_Note: It will likely give you a certificate error as ICP was installed with a self signed certificate._

![ICP Login Page](images/icp-login-page.png)

Click on `admin` on the top right hand corner of the screen to bring up a menu and select "Configure Client".

![ICP Configure Client](images/icp-configure-client.png)

Copy and Paste the provided commands into a shell:

```bash
kubectl config set-cluster mycluster.icp --server=https://192.168.27.100:8001 --insecure-skip-tls-verify=true
kubectl config set-context mycluster.icp-context --cluster=mycluster.icp
kubectl config set-credentials mycluster.icp-user --token=eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImF0X2hhc2giOiJFaGllVkp1T3VtNEVyWVI0d2NjUThBIiwiaXNzIjoiaHR0cHM6Ly9teWNsdXN0ZXIuaWNwOjk0NDMvb2lkYy9lbmRwb2ludC9PUCIsImF1ZCI6ImM2ZDk3NTdmYWY0NmIyNDBkNTJjNDkyMjg0YzQxYmY5IiwiZXhwIjoxNTA5NjgxNjc0LCJpYXQiOjE1MDk2Mzg0NzR9.oLvpbbmJLnxf-ALAMc7vku-EU7ucp1JEixYf6OALkk76oNsVYhVVWKMyfZWU2IMH98ivo1INAU5SRl2w2bQjvwkzMsa3UScu1XR7GFm3XOl4SUWOGFCxfjxaR7n0zEIH0kaLvsrNUIiHl3kE70HuYcNU1MsOwq9u3NfzaDZnHQFu8NFOeGpsI26GlKrqlT_ROz7bsuQ1-M5KOMV4vjKKL6o95d_Ab0Nb7HXn58jXONRQNEQYPCUWVBJQDbyzq-3zWOFUz_ev8YamQgCDOdaU-Gk2MmiInDAPPvExG6vasBQ4fXyWpoeprPtwkCOAb-bEHFdLL4v4fwQK9RfLS4ZyTQ
kubectl config set-context mycluster.icp-context --user=mycluster.icp-user --namespace=default
kubectl config use-context mycluster.icp-context
```

Check that you can run some basic commands against the cluster:

```bash
$ kubectl version
Client Version: version.Info{Major:"1", Minor:"7", GitVersion:"v1.7.3", GitCommit:"2c2fe6e8278a5db2d15a013987b53968c743f2a1", GitTreeState:"clean", BuildDate:"2017-08-03T07:00:21Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"darwin/amd64"}
Server Version: version.Info{Major:"1", Minor:"7+", GitVersion:"v1.7.3-7+154699da4767fd", GitCommit:"154699da4767fd4225cbaa91cc26abd71bc853c7", GitTreeState:"clean", BuildDate:"2017-08-28T06:41:56Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}
$ kubectl get nodes
NAME             STATUS    AGE       VERSION
192.168.27.100   Ready     23h       v1.7.3-7+154699da4767fd
192.168.27.101   Ready     23h       v1.7.3-7+154699da4767fd
192.168.27.102   Ready     23h       v1.7.3-7+154699da4767fd
192.168.27.111   Ready     23h       v1.7.3-7+154699da4767fd
```

From here you should be able to interact with ICP via either the Web UI or the `kubectl` command.
