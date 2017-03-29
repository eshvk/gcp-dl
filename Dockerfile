# Refer https://github.com/fastai/courses/blob/master/setup/install-gpu.sh
FROM nvidia/cuda:8.0-cudnn5-devel
# CONDA
RUN mkdir downloads && \
	cd downloads && \
	wget "https://repo.continuum.io/archive/Anaconda2-4.2.0-Linux-x86_64.sh" -O "Anaconda2-4.2.0-Linux-x86_64.sh" && \
	bash "Anaconda2-4.2.0-Linux-x86_64.sh" -b && \
	echo "export PATH=\"$HOME/anaconda2/bin:\$PATH\"" >> ~/.bashrc && \
	export PATH="$HOME/anaconda2/bin:$PATH" && \
	conda install -y bcolz && \
	conda upgrade -y --all
# THEANO
RUN pip install theano && \
	echo "[global] && \
	device = gpu && \
	floatX = float32 && \
	[cuda] && \
	root = /usr/local/cuda" > ~/.theanorc
# KERAS
RUN pip install keras==1.2.2 && \
	mkdir ~/.keras && \
	echo '{ \
    "image_dim_ordering": "th", \
    "epsilon": 1e-07, \
    "floatx": "float32", \
    "backend": "theano" \
	}' > ~/.keras/keras.json
# install cudnn libraries
RUN wget "http://platform.ai/files/cudnn.tgz" -O "cudnn.tgz" && \
	tar -zxf cudnn.tgz && \
	cd cuda && \
	sudo cp lib64/* /usr/local/cuda/lib64/ && \
	sudo cp include/* /usr/local/cuda/include/
