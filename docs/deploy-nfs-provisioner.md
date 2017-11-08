## Deploy nfs-provisioner on ICP master

Several helm charts packaged with IBM Cloud Private and also available from the community require storage for persistence. You can perform this optional step to configure a [nfs dynamic provisioner](https://github.com/kubernetes-incubator/external-storage/tree/master/nfs) to simplify setting up backing storage for applications deployed with helm charts. These steps are designed to make a simple provisioner for use in testing of ICP. For more details on configuration options for production cluster, see the [full deployment options](https://github.com/kubernetes-incubator/external-storage/blob/master/nfs/docs/deployment.md).

#### Requirements
The dynamic NFS provisioner that is created with these instructions will use storage space available from the ICP master node that can be mapped as a hostPath. Persistent volumes created by the provisioner will only be able to accommodate requests for space available in this path. The [Deploy in local VMs using Vagrant](deploy-vagrant.md) instructions create a directory with 500 GiB available under `/storage`.

1.  Log in to the icp master node and create a directory for the nfs provisioner. The nfs-provisioner file is set with the `hostPath: /storage/dynamic` . If you select a different path to create in this step, also update the `extensions/nfs-deployment.yaml` file with this path.

    *   If using the Vagrant build run these commands:

        ```bash
        vagrant ssh
        sudo mkdir -p /storage/dynamic
        ```

    *   If using Softlayer hosted VMs run:

        ```bash
        ssh-add cluster/ssh_key
        ssh root@<replace_with_you_icp-master01_IPADDRESS>
        mkdir -p /storage/dynamic
        ```

2.  If you have not done so already, log in to the web UI for ICP at the address shown after the installation has completed and follow the steps to configure the `kubectl` command prompt for use from your workstation.

3.  Run the deployment to create the nfs-provisioner container. Update the `hostPath:` field if you have used a path different from `/storage/dynamic` in the directory creation step.

    ```
    kubectl create -f extensions/nfs-deployment.yaml
    ```

    Monitor the pod creation using `kubectl get pods` or the IBM Cloud Private dashboard. Wait for it to show in the ready state before creating the test claim in step 5.

4.  Create the `nfs-dynamic` storage class:

    ```
    kubectl create -f extensions/nfs-class.yaml
    ```

5.  Create a test claim against the class and display the results:

    ```
    kubectl create -f extensions/nfs-test-claim.yaml
    kubectl get pvc
    ```

    You may delete the test claim with `kubectl delete -f extensions/nfs-test-claim.yaml`

To use the nfs-provisioner to dynamically create storage for Persistent Volume Claims, specify the storageClassName of `nfs-dynamic` for when installing applications using the Catalog of the helm cli. If the chart includes and option to useDynamicProvisioning, set this to `true` as well.
