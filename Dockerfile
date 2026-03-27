# 基础镜像保持不变
FROM nvidia/cuda:12.2.0-runtime-ubuntu22.04

USER root

# 1. 核心修复：更换为国内阿里云镜像源，解决 "File has unexpected size" 和同步问题
RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list

# 2. 安装系统依赖，加入 --fix-missing 增强容错
RUN apt-get update && apt-get install -y --fix-missing \
    python3-pip python3-dev libgl1-mesa-glx libglib2.0-0 \
    curl sqlite3 libcurl4-openssl-dev libsqlite3-dev \
    software-properties-common git \
    && add-apt-repository -y ppa:openshot.developers/libopenshot-daily \
    && apt-get update \
    && apt-get install -y onedrive \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. 升级构建工具，这对安装 sentence-transformers 至关重要
RUN pip3 install --no-cache-dir --upgrade pip setuptools wheel

# 4. 分步安装：第一步安装 PyTorch 相关 (锁定 CUDA 12.1 源)
RUN pip3 install --no-cache-dir \
    torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cu121

# 5. 分步安装：第二步安装 sentence-transformers (不带 index-url，强制回退到 PyPI)
# 这一步会自动识别已安装的 torch，不会再报错找不到版本
RUN pip3 install --no-cache-dir sentence-transformers

# 6. 安装其他工具库
RUN pip3 install --no-cache-dir \
    easyocr faiss-gpu pandas openpyxl PyPDF2 \
    python-docx python-pptx pdf2image Pillow

# 7. 设置环境
# 创建必要的目录
RUN mkdir -p /app/OneDrive /app/.config/onedrive

# 关键：赋予 /app 递归的组写权限
# OpenShift 随机 UID 属于 root 组 (GID 0)，所以赋予 GID 0 权限是标准做法
RUN chgrp -R 0 /app && \
    chmod -R g=u /app

# 设置环境变量
WORKDIR /app
RUN mkdir -p /app/OneDrive /app/.config/onedrive

RUN chgrp -R 0 /app && \
    chmod -R g=u /app && \
    chmod +x /app/scanner_cuda.py

ENV HOME=/app
ENV ONEDRIVE_DATA_DIR="/app/OneDrive"
ENV ONEDRIVE_CONF_DIR="/app/.config/onedrive"
ENV HF_HUB_OFFLINE="1"
