import os, faiss, pickle, torch, json, time
import numpy as np
from pathlib import Path
from sentence_transformers import SentenceTransformer
import easyocr

# 强制使用 CUDA (4070 Ti S)
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

def run_remote_scan(doc_dir, db_dir):
    os.makedirs(db_dir, exist_ok=True)
    manifest_path = os.path.join(db_dir, "manifest.json")
    
    # 1. 加载模型到 4070 Ti S
    # 注意：这里不需要 local_files_only，因为 Pod 访问 HuggingFace 通常比内网快
    embedder = SentenceTransformer("BAAI/bge-m3", device=DEVICE)
    reader = easyocr.Reader(['ch_sim', 'en'], gpu=True) # 开启 GPU OCR
    
    files = list(Path(doc_dir).glob("**/*.*"))
    current_status = {str(f): os.path.getmtime(f) for f in files}
    
    # 2. 解析与向量化逻辑 (与笔记本一致以保证兼容)
    all_chunks, all_texts = [], []
    for f in files:
        # 此处调用你之前 app.py 里的 extract_text_advanced 逻辑
        # ... (解析逻辑省略，保持一致即可)
        pass

    if all_texts:
        # 利用 GPU 进行 Batch 编码，4070 Ti S 可以设置很大的 batch_size
        embs = embedder.encode(all_texts, batch_size=64, show_progress_bar=True, normalize_embeddings=True)
        
        # 3. 生成笔记本可用的 CPU 索引
        # 虽然在 GPU 上算，但我们要存为 IndexFlatL2，这样笔记本加载时不需要显卡
        idx = faiss.IndexFlatL2(embs.shape[1])
        idx.add(np.array(embs))
        
        faiss.write_index(idx, os.path.join(db_dir, "faiss.index"))
        with open(os.path.join(db_dir, "chunks.pkl"), "wb") as f:
            pickle.dump(all_chunks, f)
        with open(manifest_path, 'w') as f:
            json.dump(current_status, f)
        print(f"✨ 扫描完成，索引已存入 {db_dir}")

if __name__ == "__main__":
    # 可以通过环境变量或 cron 定期触发
    run_remote_scan("my_work_docs", "db_work")
