# Deploy IBM Cloud Private

Instructions:

* [Deploy in local VMs using Vagrant](docs/deploy-vagrant.md)
* [Deploy in Softlayer VMs using Ansible](docs/deploy-softlayer-ansible.md)
* [Deploy in Softlayer VMs using Terraform](docs/deploy-softlayer-terraform.md)
* [Deploy in OpenStack using Terraform](docs/deploy-openstack-terraform.md)


## Accessing IBM Cloud Private

Access the URL using the username, password provided in last few lines of the ICP deployment.

_Note: It will likely give you a certificate error as ICP was installed with a self signed certificate._

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

Please refer to the embedded README document in *terraform/openstack*
for detailed deployment steps.
