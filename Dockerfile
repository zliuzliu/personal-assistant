# 使用 NVIDIA CUDA 官方镜像作为基础，确保 4070 Ti S 的兼容性
FROM nvidia/cuda:12.2.0-runtime-ubuntu22.04

# 安装系统依赖：D 语言编译器 (用于 onedrive)、Python、以及 OCR 依赖
RUN apt-get update && apt-get install -y \
    python3-pip python3-dev libgl1-mesa-glx libglib2.0-0 \
    curl sqlite3 libcurl4-openssl-dev libsqlite3-dev \
    software-properties-common && \
    add-apt-repository ppa:openshot.developers/libopenshot-daily && \
    apt-get update && \
    # 安装 abraunegg/onedrive 客户端
    apt-get install -y onedrive && \
    rm -rf /var/lib/apt/lists/*

# 安装 Python 核心 AI 组件
RUN pip3 install --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 \
    sentence-transformers easyocr faiss-gpu pandas openpyxl PyPDF2 \
    python-docx python-pptx pdf2image Pillow

WORKDIR /app
# 这里的 scanner_cuda.py 是我之前提到的纯 Python 扫描脚本
COPY scanner_cuda.py /app/scanner_cuda.py

# 创建挂载点
RUN mkdir -p /app/onedrive_data /app/db_sync

# 启动脚本：先同步 OneDrive，再执行扫描
CMD ["/bin/bash", "-c", "onedrive --synchronize && python3 /app/scanner_cuda.py && onedrive --synchronize"]
