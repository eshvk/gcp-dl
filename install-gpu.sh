# This script is designed to work with ubuntu 16.04 LTS
# It is based on Fast.AI's GPU install.
#! /bin/bash
echo "Checking for CUDA and installing."
# Check for CUDA and try to install.
if ! dpkg-query -W cuda; then
	curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_8.0.61-1_amd64.deb
	dpkg -i ./cuda-repo-ubuntu1604_8.0.61-1_amd64.deb
	apt-get update
	apt-get install cuda -y
fi
# Check if startup script has worked.
nvidia-smi