# gcp-dl
Quickly and easily setup a cloud machine for Deep Learning in GCP. The quickly, easily parts are WIP.

## STEPS

- Create [GPU Instance](https://cloud.google.com/compute/docs/gpus/add-gpus#create-new-gpu-instance) on a VM and run it.

For example, if I want to run a one GPU, 4 CPU instance in `us-east`-d` and install CUDA on it.

```
gcloud beta compute instances create eshvk-dl-fastai \
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
    --machine-type n1-standard-4 --zone us-east1-d \
    --accelerator type=nvidia-tesla-k80,count=1 \
    --image-family ubuntu-1604-lts --image-project ubuntu-os-cloud \
    --maintenance-policy TERMINATE --restart-on-failure \
    --metadata-from-file startup-script=install-gpu.sh
 ```


## Technical Notes
Here is a very brief overview of the different moving parts.

- [`docker`](https://www.docker.com/) provides a container which is very similar to a VM, except that it involves OS level virtualization.

- [`kubernetes`](https://kubernetes.io/) is what Google uses to maintain and manage swarms of containers.

- [`nvidia-docker`](https://github.com/NVIDIA/nvidia-docker/wiki/Why%20NVIDIA%20Docker). In order to run a GPU based process on a NVIDIA GPU based machine, we need the NVIDIA driver to be installed. This kind of breaks the docker abstraction of being hardware and platform agnostic. This tools helps plug that leaky abstraction.

## Credits
This is based on the excellent [easy-python-ml](github.com/flylo/easy-python-ml) repo, [fast.ai](https://github.com/fastai/courses/tree/master/setup)'s course and [nvidia-docker](https://github.com/NVIDIA/nvidia-docker).

