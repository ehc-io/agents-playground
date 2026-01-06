#!/bin/bash
pybin="/usr/bin/python3.10"

### Dev instance
apt-get update

## PIP installation
curl -O https://bootstrap.pypa.io/get-pip.py && $pybin  ./get-pip.py

## install psutil (required for ipyKernel)
## gcloud utils
# echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
# curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
# sudo apt-get update && sudo apt-get install google-cloud-cli
# $pybin -m pip install git+https://github.com/giampaolo/psutil.git

# # PIP modules
# $pybin -m pip install pillow pydub colorama pymongo python-slugify bs4 scrapy langdetect
# $pybin -m pip install unstructured pdf2image pdfminer pdfminer.six pypdf pytesseract 
# $pybin -m pip install PyMuPDF fpdf PyPDF2 apify_client youtube-transcript-api pytube
# $pybin -m pip install tweepy boto3 python-slugify streamlit streamlit_chat kor
# $pybin -m pip install torch transformers wikipedia 
# $pybin -m pip install langchain openai tiktoken openai-whisper 
# $pybin -m pip install google-cloud-aiplatform google-cloud-speech 

# # genAI Add-ons
# $pybin -m pip install datasets sentence-transformers
# # 
# # manual installations
# apt-get install gcc-9 g++-9
# update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 60 --slave /usr/bin/g++ g++ /usr/bin/g++-9\n
# apt-get update
# apt-get install g++-aarch64-linux-gnu
# $pybin -m pip install git+https://github.com/chroma-core/chroma.git
# $pybin -m pip install git+https://github.com/scikit-learn/scikit-learn.git
# $pybin -m pip install git+https://github.com/facebookresearch/detectron2.git
# $pybin -m pip install git+https://github.com/pysqlite3/pysqlite3.git
# # to fix 
# # $pybin -m pip install git+https://github.com/abetlen/llama-cpp-python.git
