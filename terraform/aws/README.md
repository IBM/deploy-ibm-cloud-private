# Terraform Highly Available ICP Deployment on AWS

This Terraform configurations uses the [AWS provider](https://www.terraform.io/docs/providers/aws/index.html) to provision virtual machines on VMware
and [TerraForm Module ICP Deploy](https://github.com/ibm-cloud-architecture/terraform-module-icp-deploy) to prepare VMs and deploy [IBM Cloud Private](https://www.ibm.com/cloud-computing/products/ibm-cloud-private/) on them.  This Terraform template automates best practices learned from installing ICP on AWS at numerous client sites in production.

This template provisions an HA cluster with ICP 2.1.0.2 enterprise edition.

* [Infrastructure Architecture](#infrastructure-architecture)
* [Terraform Automation](#terraform-automation)
* [Installation Procedure](#installation-procedure)
* [Cluster access](#cluster-access)
* [AWS Cloud Provider](#aws-cloud-provider)

## Infrastructure Architecture
The following diagram outlines the infrastructure architecture.

  ![Infrastructure Architecture](imgs/icp_ha_aw_overview.png?raw=true)

In a single availability zone, we divide the network into a public subnet which is directly connected to the internet, and a private subnet that can reach the internet through the NAT gateway:

  ![Single Availability Zone Infrastructure](imgs/icp_ha_aws_single_az.png?raw=true)

## Terraform Automation

### Prerequisites

1. To use Terraform automation, download the Terraform binaries [here](https://www.terraform.io/).

   On MacOS, you can acquire it using [homebrew](brew.sh) using this command:

   ```bash
   brew install terraform
   ```

1. (optional) Create an S3 bucket in the same region that the ICP cluster will be created and upload the ICP binaries.  Make note of the bucket name.  You can use the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/awscli-install-bundle.html) to do this.  Note, if you are doing the optional next step, you do not need to do this.

3. (optional) Create an AMI to use as the base image for some or all instances. You can optionally install Docker and pre-load the ICP images.  Make note of the AMI ID.  This can be done using the following steps:

  1. Create an EC2 Instance in the same region that ICP will be installed in.  Ensure the root disk size is at least 100GB.

  2. [Install Docker](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0/installing/install_docker.html) in the EC2 Instance.  Make sure Docker starts automatically:

     ```bash
     systemctl enable docker
     ```

  3. Copy the IBM Cloud Private binary tarball into the EC2 Instance.

  4. Load the images into the local Docker repository.

     ```bash
     tar xf ibm-cloud-private-x86_64-2.1.0.2.tar.gz -O | sudo docker load
     ```

  5. Install the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/awscli-install-bundle.html).

  6. Convert the instance into an AMI.

4. Create a file, `terraform.tfvars` containing the values for the following:

|name | required                        | value        |
|----------------|------------|--------------|
| `aws_region`   | no           | AWS region that the VPC will be created in.  By default, uses `us-east-2`.  Note that the AWS selected region should have at least 3 availability zones. |
| `azs`          | no           | AWS Availability Zones that the VPC will be created in, e.g. `[ "a", "b", "c"]` to install in three availability zones.  By default, uses `["a", "b", "c"]`.  Note that the AWS selected region should have at least 3 availability zones for high availability.  Setting to a single availability zone will disable high availability and not provision EFS. |
| `key_name`     | yes          | AWS keypair name to assign to instances     |
| `docker_package_location` | no         | S3 URL of the ICP docker package for RHEL (e.g. `s3://<bucket>/<filename>`). Ubuntu will use `docker-ce` from the [Docker apt repository](https://docs.docker.com/install/linux/docker-ce/ubuntu/).  If Docker is already installed in the base AMI, this step will be skipped. |
| `image_location` | no         | S3 URL of the ICP binary package (e.g. `s3://<bucket>/ibm-cloud-private-x86_64-2.1.0.2.tar.gz`).  Can also be a local path, e.g. `./icp-install/ibm-cloud-private-x86_64-2.1.0.2.tar.gz`; in this case the Terraform automation will create an S3 bucket and upload the binary package.  If provided, the automation will download the binaries from S3 and perform a `docker load` on every instance.  Note that it is faster to create an instance, install docker, perform the `docker load`, and convert to an AMI for use as a base instance for all node role types, as loading docker images takes around 20 minutes per EC2 instance. If the installer image is already on the EC2 instance, this step is skipped. |
| `icp_inception_image` | no | Name of the bootstrap installation image.  By default it uses `ibmcom/icp-inception:2.1.0.2-ee` to indicate 2.1.0.2 EE, but this will vary in each release.  You can also install ICP Community edition by specifying `ibmcom/icp-inception:2.1.0.2` for example, |
| `existing_iam_instance_profile_name` | no | If an IAM role is created beforehand, will assign the role with this name to all EC2 instances. See section on IAM roles for more information on the required policies. If blank, will attempt to create an IAM role.|
| `user_provided_cert_dns` | no | The DNS name in a user-provided TLS certificate, if provided |

See [Terraform documentation](https://www.terraform.io/intro/getting-started/variables.html) for the format of this file.

5. If using a user-provided TLS certificate containing a custom DNS name, copy `icp-auth.crt` and `icp-auth.key` to this directory before installation to the `cfc-certs` directory.  See [documentation](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0/installing/create_ca_cert.html) for more details.  The certificate should contain the `user_provided_cert_dns` as a common name, and the DNS entry corresponding should be a CNAME pointing at the created ELB DNS entry for the master console.

6. Provide AWS credentials using environment variables:

   ```bash
   export AWS_ACCESS_KEY_ID=ENTER_KEY_HERE
   export AWS_SECRET_ACCESS_KEY=ENTER_KEY_HERE
   ```

7. Initialize Terraform using this command.  This will download all dependent modules, including the [ICP installation module](https://github.com/ibm-cloud-architecture/terraform-module-icp-deploy).

   ```bash
   terraform init
   ```

### Run the Terraform Automation

Run this command to see what would be created in the AWS account:

```bash
terraform plan
```

To move forward and create the objects, use the following command:

```bash
terraform apply
```

This will kick off all infrastructure objects.  Once the infrastructure is created, the installation runs silently on the boot master (i.e. `icp-master01`) until it completes.  To monitor the installation, you can provision a bastion host which is placed on the public subnet and use it as a jumpbox into the `icp-master01` host.  The installation output will be written to `/var/log/cloud-init-output.log`.

When the installation completes,  the `/opt/ibm/cluster` directory on the boot master (i.e. `icp-master01`) is backed up to S3 in a bucket named `icpbackup-<clusterid>`, which can be used in master recovery in case one of the master nodes fails.  It is recommended after every time `terraform apply` is performed, to commit the `terraform.tfstate` into git so that the state is stored in source control.

When installation completes, if a user-provided certificate is used, create a CNAME entry in your DNS provider from the DNS entry to the ELB DNS URL output at the end of the terraform process.

### Terraform objects

The Terraform automation creates the following objects.

#### EC2 Instances

*these are tagged with the cluster id for Kubernetes-AWS integration*

| Node Role | Count | AWS EC2 Instance Type | Subnet | Security Group(s) |
|-----------|-------|-----------------------|--------|-------------------|
| Bastion   |   0   | t2.large              | public | icp-default, icp-bastion |
| Master    |   3   |  m4.xlarge            | private | icp-default, icp-master |
| Management |  3   | m4.xlarge             | private | icp-default, icp-management |
| VA        | 3     | m4.xlarge             | private | icp-default, icp-va |
| Proxy     |   3   | m4.large              | private | icp-default, icp-proxy |
| Worker    |  > 3   | m4.xlarge             | private | icp-default, icp-worker |

*(the instance types, base AMIs and counts can be configured in `variables.tf`)*

#### Elastic Network Interfaces

For recovery, master and proxy nodes have Network Interfaces created and attached to them as the first network device.  The private IP address is bound to the network interface, so when the interface is attached to a newly created instance, the IP address is preserved.  This is useful for Master Recovery, which is covered in below.

#### IAM Configuration

An IAM role is created in AWS and attached to each EC2 instance with the following policy:

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:Describe*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ec2:AttachVolume",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ec2:DetachVolume",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["ec2:*"],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": ["elasticloadbalancing:*"],
      "Resource": ["*"]
    }
  ]
}
```

*(The Kubernetes AWS Cloud Provider needs access to read information from the AWS API about the instance (i.e. which subnet it's in, the private DNS name, whether nodes that have been removed, etc), and to create LoadBalancers and EBS Volumes on demand.)*

Additionally, we add `S3FullAccess` policy so that the IAM role can get installation images out of an S3 bucket and back up the `/opt/ibm/cluster` directory to an S3 bucket after installation.

#### VPC
- VPC with an internet gateway
- All ICP nodes are placed in private subnets, each with their own NAT Gateway.
  - outbound Internet access from private subnet through NAT Gateway

#### Subnets
- two for each AZ (one public, one private)
  - *(CIDR for VPC and subnets can be configured in `terraform.tfvars`, see `variables.tf for values`)*
  - *(these are tagged with the cluster id for Kubernetes ELB integration)*

#### Security Group
Note that the below are the defaults, and each security group can have its whitelist be configured in `terraform.tfvars`.
- `icp-bastion`
  - allow 22 from 0.0.0.0/0
- `icp-default`
  - allow ALL traffic from itself *(all nodes are in this security group)*
  - *(this is tagged with the cluster id for Kubernetes ELB integration)*
- `icp-proxy-80`
  - allow from 0.0.0.0/0 on port 80
- `icp-proxy-443`
  - allow from 0.0.0.0/0 on port 443
- `icp-master-9443`
  - allow from internal on port 9443 (auth service)
- `icp-master-8500`
  - allow from 0.0.0.0/0 on port 8500 (image registry)
  - allow from internal on port 8001 (kube api)
- `icp-master-8443`
  - allow from 0.0.0.0/0 on port 8443 (master UI)
  - allow from internal on port 8001 (kube api)
- `icp-master-8001`
  - allow from 0.0.0.0/0 on port 8001 (kube api)
  - allow from internal on port 8001 (kube api)
- `icp-workers`
  - allow all traffic from self (future use)
- `icp-management`
  - allow all traffic from self (future use)
- `icp-va`
  - allow all traffic from self (future use)
- efs mounts
  - allow all from icp master nodes

#### Elastic File System Storage
If more than one master node is provisioned, EFS mounts are created for shared storage:
- two volumes (both at least 20GB)
  - /var/lib/registry (image registry)
  - /var/lib/icp/audit (audit logs)

Note that not every AWS Region supports EFS.

#### Load Balancer

*Note that in AWS, the Network LoadBalancer type does not have explicit security groups are instead placed on the instances themselves.*

- Network LoadBalancer for ICP console
  - listen on 8443, forward to master nodes port 8443 (ICP Console)
  - listen on 8001, forward to master nodes port 8001 (Kubernetes API)
  - listen on 8500, forward to master nodes port 8500 (Image registry)
  - listen on 9443, forward to master nodes port 9443 (Auth service)
- Network LoadBalancer for ICP Ingress resources
  - listen on port 80, forward to proxy nodes port 80 (http)
  - listen on port 443, forward to proxy nodes port 443 (https)

#### Route53 DNS Zone

For convenience, a private DNS Zone is created in Route 53.  The domain name can be configured in `variables.tf`; by default it is `<clusterid>.icpcluster.icp`.  The domain search suffixes are added to `resolv.conf`, but due to a bug in cloud-init, `resolv.conf` is overwritten by NetworkManager in RHEL. It should be resolved in a future release of cloud-init.

#### S3 Bucket

1. An S3 Bucket for Configuration is created and the `/opt/ibm/cluster` is uploaded after the cluster is installed.  This is not deleted after an `terraform destroy`.
2. An S3 bucket is created for ICP installation binaries.  This is not deleted after `terraform destroy`.

#### Auto-scaling group (BETA)

An auto-scaling group for the ICP worker nodes is created containing the same configuration as the ICP worker nodes, if `enable_autoscaling` is set to `true`.  Scaling up and down is triggered manually.

#### Lambda function (BETA)

A Lambda function is created that responds to the auto-scaling events, if `enable_autoscaling` is set to `true`.  The function is zipped and uploaded to an S3 bucket, along with client certificates used to talk to the Kubernetes API. The function creates Kubernetes jobs in ICP that add and remove worker nodes from the cluster using the `icp-inception` image.  The function runs from within the VPC.

## Installation Procedure

The installer automates the install procedure described [here](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0/installing/installing.html).

### ICP Installation Parameters on AWS

Suggested ICP Installation parameters specific on AWS:

```
---
calico_tunnel_mtu: 8981
cloud_provider: aws
kubelet_nodename: fqdn
```

Because AWS enables Jumbo frames (MTU 9001), the Calico IP-in-IP tunnel is configured to take advantage of the larger MTU.

The `cloud_provider` parameter allows Kubernetes to take advantage of some Kubernetes-AWS integration with dynamic ELB creation and dynamic EBS creation for persistent volumes.  When the AWS `cloud_provider` is used, all node names use the private FQDN retrieved from from the AWS metadata service and nodes are tagged with the correct region and availability zone.  Kubernetes will stripe deployments across availability zones.  See the [below section](#aws-cloud-provider) for more details.

The Terraform automation generates `cluster_CA_domain`, `cluster_lb_address`, and `proxy_lb_address` corresponding to the DNS names for the master and proxy ELB.

Note the other parameters in the `icp-deploy.tf` module.  The config files are stored in `/opt/ibm/cluster/config.yaml` on the boot-master.

## Cluster access

### ICP Console access

The ICP console can be accessed at `https://<cluster_lb_address>:8443`.  See [documentation](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0/manage_cluster/cfc_gui.html).

### ICP Private Image Registry access

The registry is available at `https://<cluster_lb_address>:8500`.  See [documentation](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0/manage_images/configuring_docker_cli.html) for how to configure Docker to access the registry.

### ICP Kubernetes API access

The Kubernetes API can be reached at `https://<cluster_lb_address>:8001`.  To obtain a token, see the [documentation](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0/manage_cluster/cfc_cli.html) or this [blog post](https://www.ibm.com/developerworks/community/blogs/fe25b4ef-ea6a-4d86-a629-6f87ccf4649e/entry/Configuring_the_Kubernetes_CLI_by_using_service_account_tokens1?lang=en),

### ICP Ingress Controller

[Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/) can be created and exposed using the proxy node endpoints at `http://<proxy_lb_address>:80` or `https://<proxy_lb_address>:443`

## AWS Cloud Provider

The AWS Cloud provider provides Kubernetes integration with Elastic Load Balancer and Elastic Block Store.  See documentation on [LoadBalancer](https://kubernetes.io/docs/concepts/cluster-administration/cloud-providers/#aws) and [Volume](https://kubernetes.io/docs/concepts/storage/storage-classes/#aws)
