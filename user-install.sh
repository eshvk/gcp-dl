# install Anaconda for current user
mkdir downloads
cd downloads
wget "https://repo.continuum.io/archive/Anaconda2-4.2.0-Linux-x86_64.sh" -O "Anaconda2-4.2.0-Linux-x86_64.sh"
bash "Anaconda2-4.2.0-Linux-x86_64.sh" -b

echo "export PATH=\"$HOME/anaconda2/bin:\$PATH\"" >> ~/.bashrc
export PATH="$HOME/anaconda2/bin:$PATH"
conda install -y bcolz
conda upgrade -y --all

# install and configure theano
pip install theano
echo "[global]
device = gpu
floatX = float32
[cuda]
root = /usr/local/cuda" > ~/.theanorc

# install and configure keras
pip install keras==1.2.2
mkdir ~/.keras
echo '{
    "image_dim_ordering": "th",
    "epsilon": 1e-07,
    "floatx": "float32",
    "backend": "theano"
}' > ~/.keras/keras.json

# install cudnn libraries
wget "http://platform.ai/files/cudnn.tgz" -O "cudnn.tgz"
tar -zxf cudnn.tgz
cd cuda
sudo cp lib64/* /usr/local/cuda/lib64/
sudo cp include/* /usr/local/cuda/include/

# configure jupyter and prompt for password
jupyter notebook --generate-config
jupass=`python -c "from notebook.auth import passwd; print(passwd())"`
echo "c.NotebookApp.password = u'"$jupass"'" >> $HOME/.jupyter/jupyter_notebook_config.py
echo "c.NotebookApp.ip = '*'
c.NotebookApp.open_browser = False" >> $HOME/.jupyter/jupyter_notebook_config.py

# Install Google Cloud Storage Tools to get data from GCS.
pip install google-api-python-client google-cloud-storage
echo "export GOOGLE_APPLICATION_CREDENTIALS=\"$HOME/google_service_key.json\"" >> ~/.bashrc
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/google_service_key.json"
 curl https://dl.google.com/dl/cloudsdk/channels/rapid/google-cloud-sdk.zip > google-cloud-sdk.zip \
 && unzip google-cloud-sdk.zip && rm google-cloud-sdk.zip \
 && google-cloud-sdk/install.sh --usage-reporting=true --path-update=true --bash-completion=true \
 && google-cloud-sdk/bin/gcloud config set --installation component_manager/disable_update_check true \
 && sed -i -- 's/\"disable_updater\": false/\"disable_updater\": true/g' google-cloud-sdk/lib/googlecloudsdk/core/config.json
echo "export PATH=\"$HOME/google-cloud-sdk/bin:\$PATH\"" >> ~/.bashrc

# clone the fast.ai course repo and prompt to start notebook
cd ~
git clone https://github.com/fastai/courses.git
echo "\"auth_and_start.sh jupyter notebook\" will start Jupyter on port 8888"
echo "If you get an error instead, try restarting your session so your $PATH is updated"
