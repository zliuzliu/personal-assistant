import os, faiss, pickle, torch, json, time
import numpy as np
from pathlib import Path
from sentence_transformers import SentenceTransformer
import easyocr

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

def get_file_fingerprint(path):
    """获取文件指纹：修改时间 + 文件大小"""
    stat = os.stat(path)
    return [stat.st_mtime, stat.st_size]

def run_remote_scan(doc_dir, db_dir):
    os.makedirs(db_dir, exist_ok=True)
    manifest_path = os.path.join(db_dir, "manifest.json")
    
    # 加载现有清单
    old_manifest = {}
    if os.path.exists(manifest_path):
        with open(manifest_path, 'r') as f: old_manifest = json.load(f)

    embedder = SentenceTransformer("BAAI/bge-m3", device=DEVICE)
    reader = easyocr.Reader(['ch_sim', 'en'], gpu=True)
    
    files = list(Path(doc_dir).glob("**/*.*"))
    new_manifest = {}
    needs_rebuild = False

    # 校验是否有文件变动
    for f in files:
        f_str = str(f)
        fingerprint = get_file_fingerprint(f)
        new_manifest[f_str] = fingerprint
        if f_str not in old_manifest or \
           abs(old_manifest[f_str][0] - fingerprint[0]) > 2 or \
           old_manifest[f_str][1] != fingerprint[1]:
            needs_rebuild = True

    if not needs_rebuild and os.path.exists(os.path.join(db_dir, "faiss.index")):
        print("✅ 无文件变动，跳过扫描。")
        return

    # ... 执行完整扫描逻辑 (同前) ...
    # 存入 new_manifest
    with open(manifest_path, 'w') as f: json.dump(new_manifest, f)
