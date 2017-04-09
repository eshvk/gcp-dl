# gcp-dl
Quickly and easily setup a cloud machine for Deep Learning Experimentation in GCP. The quickly, easily parts are WIP.

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

- Get GCS Service Key (to run notebook/jobs remotely)
In order to run a notebook or jobs remotely, [get a service key in the GCS console](https://console.cloud.google.com/iam-admin/serviceaccounts/). Once you've downloaded this key, rename it `google_service_key.json` and move it to the root directory of the repository.

- Copy the script `user-install.sh` to the gcloud instance like so:

```
gcloud compute copy-files user-install.sh eshvk-dl-fastai:~/user-install.sh  --zone us-east1-d
```
- Copy the service key `google_service_key.json` over similarly.
```
gcloud compute copy-files google_service_key.json eshvk-dl-fastai:~/google_service_key.json  --zone us-east1-d
```
- Copy the files `auth_and_start.sh` and `lookup_value_from_json` over.
```
gcloud compute copy-files auth_and_start.sh eshvk-dl-fastai:/usr/local/bin/auth_and_start.sh  --zone us-east1-d
```


- SSH in, move the files `auth_and_start.sh`, `lookup_value_from_json` to `/usr/local/bin`run the script using `./user-install.sh`.

- Firewall forwarding rules:

```
# this enables jupyter to talk to the external world.
gcloud compute firewall-rules create default-allow-jupyter --allow tcp:8888  --target-tags=allow-jupyter
# Add this to your instance
gcloud compute instances add-tags eshvk-dl-fastai --tags allow-jupyter --zone us-east1-d

```

- Now SSH into the machine, do 'jupyter notebook' and log on on your browser with something like `http://<external-ip>:8888`.


## Credits
This is based on [fast.ai](https://github.com/fastai/courses/tree/master/setup)'s course setup.