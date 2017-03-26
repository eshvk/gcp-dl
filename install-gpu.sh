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
# Install Docker From https://docs.docker.com/engine/installation/linux/ubuntu/#install-using-the-repository
# sudo apt-get remove docker docker-engine
# sudo apt-get update
# sudo apt-get install \
#     apt-transport-https \
#     ca-certificates \
#     curl \
#     software-properties-common
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# sudo apt-key fingerprint 0EBFCD88
# sudo add-apt-repository \
#    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
#    $(lsb_release -cs) \
#    stable"
# sudo apt-get update
# # This should probably be a specific version
# sudo apt-get install docker-ce -y
# sudo docker run hello-world

