# gcp-dl
Quickly and easily setup a cloud machine for Deep Learning in GCP.

## Credits
This is based on the excellent [easy-python-ml](github.com/flylo/easy-python-ml), [fast.ai](https://github.com/fastai/courses/tree/master/setup)'s course and [nvidia-docker](https://github.com/NVIDIA/nvidia-docker).

## Technical Notes
Here is a very brief overview of the different moving parts.

- [`docker`](https://www.docker.com/) provides a container which is very similar to a VM, except that it involves OS level virtualization.

- [`kubernetes`](https://kubernetes.io/) is what Google uses to maintain and manage swarms of containers.

- [`nvidia-docker](https://github.com/NVIDIA/nvidia-docker/wiki/Why%20NVIDIA%20Docker). In order to run a GPU based process on a NVIDIA GPU based machine, we need the NVIDIA driver to be installed. This kind of breaks the docker abstraction of being hardware and platform agnostic. This tools helps plug that leaky abstraction.


## STEPS

- Create GPU Instance on a VM and run it.
`gcloud beta compute instances create [INSTANCE_NAME] \
    --machine-type [MACHINE_TYPE] --zone [ZONE] \
    --accelerator type=[ACCELERATOR_TYPE],count=[ACCELERATOR_COUNT] \
    --image-family [IMAGE_FAMILY] --image-project [IMAGE_PROJECT] \
    --maintenance-policy TERMINATE --restart-on-failure \
    --metadata startup-script='[STARTUP_SCRIPT]'`


