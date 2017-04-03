# gcp-dl
Quickly and easily setup a cloud machine for Deep Learning in GCP. The quickly, easily parts are WIP.

## STEPS

### Completely Script Based Approach

- Create [GPU Instance](https://cloud.google.com/compute/docs/gpus/add-gpus#create-new-gpu-instance) on a VM and run it.

For example, if I want to run a one GPU, 4 CPU instance in `us-east`-d` with 1TB SSD bootdisk and install CUDA on it.

```
gcloud beta compute instances create eshvk-dl-fastai \
    --boot-disk-size=1TB --boot-disk-type= \
    --machine-type n1-standard-4 --zone us-east1-d \
    --accelerator type=nvidia-tesla-k80,count=1 \
    --image-family ubuntu-1604-lts --image-project ubuntu-os-cloud \
    --maintenance-policy TERMINATE --restart-on-failure \
    --metadata startup-script='#!/bin/bash
    echo "Checking for CUDA and installing."
    # Check for CUDA and try to install.
    if ! dpkg-query -W cuda; then
      curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_8.0.61-1_amd64.deb
      dpkg -i ./cuda-repo-ubuntu1604_8.0.61-1_amd64.deb
      apt-get update
      apt-get install cuda -y
    fi'
 ```

- Connect to the instance and check if the CUDA driver has been installed by:

```
nvidia-smi
```

You should see something like [this](https://cloud.google.com/compute/docs/gpus/add-gpus#verify-driver-install).

**NOTE** If the driver has not been installed, you will want to first check if the driver has been installed by the startup script. Do a `tail -f /var/log/syslog`. It does take a few minutes before that happens.

- Both of these steps can be conveniently combined together like so:

```
gcloud beta compute instances create eshvk-dl-fastai \
    --boot-disk-size=1TB --boot-disk-type= \
    --machine-type n1-standard-4 --zone us-east1-d \
    --accelerator type=nvidia-tesla-k80,count=1 \
    --image-family ubuntu-1604-lts --image-project ubuntu-os-cloud \
    --maintenance-policy TERMINATE --restart-on-failure \
    --metadata-from-file startup-script=install-gpu.sh
 ```

- Create a secondary SSD disk and mount it.
```
gcloud compute disks create eshvk-dl-fastai-disk --size 10TB --type pd-ssd --zone us-east1-d

gcloud compute instances attach-disk eshvk-dl-fastai --disk  eshvk-dl-fastai-disk --zone us-east1-d

```

- SSH into the machine; Format the disk, mount it using the instructions [here](https://cloud.google.com/compute/docs/disks/add-persistent-disk).

For example:
```
# Here sdb is the device ID I get from lsblk
sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb
# Mount point
sudo mkdir -p /mnt/disks/persistent-data
# Mount disk
sudo mount -o discard,defaults /dev/sdb /mnt/disks/persistent-data
# Add an automatic mount for next time things start.
echo UUID=`sudo blkid -s UUID -o value /dev/sdb` /mnt/disks/persistent-data ext4 discard,defaults,nofail 0 2 | sudo tee -a /etc/fstab
```

- Copy the script `user-install.sh` to the gcloud instance like so:

```
gcloud compute copy-files user-install.sh eshvk-dl-fastai:~/user-install.sh  --zone us-east1-d
```

- SSH and run the script using `./user-install.sh`.

- Firewall forwarding rules:

```
# this enables jupyter to talk to the external world.
gcloud compute firewall-rules create default-allow-jupyter --allow tcp:8888  --target-tags=allow-jupyter
# Add this to your instance
gcloud compute instances add-tags eshvk-dl-fastai --tags allow-jupyter --zone us-east1-d

```

- Now SSH into the machine, do 'jupyter notebook' and log on on your browser with something like `http://<external-ip>:8888`.

### docker-machine based Approach

- Install [docker-machine](https://docs.docker.com/machine/install-machine/)

- Create [GPU Instance](https://cloud.google.com/compute/docs/gpus/add-gpus#create-new-gpu-instance) on a VM and run it. **NOTE** that I am not installing any drivers yet.

```
gcloud beta compute instances create eshvk-dl-fastai2 \
    --boot-disk-size=1TB --boot-disk-type= \
    --machine-type n1-standard-4 --zone us-east1-d \
    --accelerator type=nvidia-tesla-k80,count=1 \
    --image-family ubuntu-1604-lts --image-project ubuntu-os-cloud \
    --maintenance-policy TERMINATE --restart-on-failure
 ```

- I stop the machine and also add an IAM account and service scopes at this point. There is probably a way of doing this in one step with the above.
```
gcloud beta compute instances set-scopes eshvk-dl-fastai2 \
    --zone us-east1-d \
    --scopes https://www.googleapis.com/auth/cloud-platform \
    --service-account <SERVICE_ACCOUNT_EMAIL>
```

- Install Docker on this machine via `docker-machine`. It figures out what machine to install using the machine name.

```
docker-machine create --driver google \
    --google-project <PROJECT_NAME> \
    --google-zone us-east1-d \
    --google-use-existing eshvk-dl-fastai2
```

The following instructions for [nvidia-docker] are lifted from the [nvidia-docker](https://github.com/NVIDIA/nvidia-docker/wiki/Deploy-on-Amazon-EC2) AWS install pages.

- You will have to configure your shell once docker is installed by doing something like :
```
eval $(docker-machine env eshvk-dl-fastai2)
```

- SSH into the machine and install the CUDA drivers (*only the drivers*)

```
# SSH into the machine
docker-machine ssh aws01

# Install official NVIDIA driver package and `nvidia-docker`
sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub
sudo sh -c 'echo "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/cuda.list'
sudo apt-get update && sudo apt-get install -y --no-install-recommends cuda-drivers

# Install nvidia-docker and nvidia-docker-plugin
wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker_1.0.1-1_amd64.deb
sudo dpkg -i /tmp/nvidia-docker*.deb && rm /tmp/nvidia-docker*.deb
```

# Now, note a couple of things:

- If you are using OSX for your local machine, you can't run `nvidia-docker` to run images on the remote host. Mainly because you can't install `nvidia-docker` there. What you can do however is build your docker images, push them to a registry and pull them in the local machine and run them. That way your image destruction doesn't affect the machine. You can swap in and swap out machines. See [here](https://cloud.google.com/container-optimized-os/docs/how-to/run-container-instance#starting_a_docker_container_via_cloud-config) for how to pull things.

## Technical Notes
Here is a very brief overview of the different moving parts.

- [`docker`](https://www.docker.com/) provides a container which is very similar to a VM, except that it involves OS level virtualization.

- [`kubernetes`](https://kubernetes.io/) is what Google uses to maintain and manage swarms of containers.

- [`docker-machine`](https://docs.docker.com/machine/) is a way to deploy docker images on remote hosts. We use this in place of kubernetes because we need to build a custom image first.

- [`nvidia-docker`](https://github.com/NVIDIA/nvidia-docker/wiki/Why%20NVIDIA%20Docker). In order to run a GPU based process on a NVIDIA GPU based machine, we need the NVIDIA driver to be installed. This kind of breaks the docker abstraction of being hardware and platform agnostic. This tools helps plug that leaky abstraction.

## Credits
This is based on the excellent [easy-python-ml](github.com/flylo/easy-python-ml) repo, [fast.ai](https://github.com/fastai/courses/tree/master/setup)'s course and [nvidia-docker](https://github.com/NVIDIA/nvidia-docker).
