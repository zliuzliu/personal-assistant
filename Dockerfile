# 使用兼容 4070 Ti S 的基础镜像
FROM nvidia/cuda:12.2.0-runtime-ubuntu22.04

USER root

# 1. 安装系统依赖
RUN apt-get update && apt-get install -y \
    python3-pip python3-dev libgl1-mesa-glx libglib2.0-0 \
    curl sqlite3 libcurl4-openssl-dev libsqlite3-dev \
    software-properties-common git \
    && add-apt-repository -y ppa:openshot.developers/libopenshot-daily \
    && apt-get update \
    && apt-get install -y onedrive \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. 第一步：仿照你提供的资料，使用 -f (find-links) 定向安装 GPU 版 Torch
# 这种方式比 --index-url 更灵活，不会锁定后续包的搜索路径
RUN pip3 install --no-cache-dir \
    torch torchvision torchaudio \
    -f https://download.pytorch.org/whl/torch_stable.html

# 3. 第二步：安装 sentence-transformers
# 此时 Torch 已存在，它不会再去寻找依赖，也就不会报错
RUN pip3 install --no-cache-dir sentence-transformers

# 4. 第三步：安装其他所有辅助库
RUN pip3 install --no-cache-dir \
    easyocr \
    faiss-gpu \
    pandas \
    openpyxl \
    PyPDF2 \
    python-docx \
    python-pptx \
    pdf2image \
    Pillow

# 5. 设置工作环境
WORKDIR /app
ENV ONEDRIVE_DATA_DIR="/app/data/onedrive"
ENV ONEDRIVE_CONF_DIR="/root/.config/onedrive"
ENV HF_HUB_OFFLINE="1"

COPY scanner_cuda.py /app/scanner_cuda.py
RUN mkdir -p /app/data/onedrive

# 6. 启动指令
CMD ["/bin/bash", "-c", "onedrive --synchronize --single-directory '02.Work/03.RedHat/Workspace/10.GenAI-PA/sync_dir' && python3 /app/scanner_cuda.py && onedrive --monitor"]
