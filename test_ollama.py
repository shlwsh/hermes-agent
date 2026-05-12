import os
import requests
import json
os.environ["no_proxy"] = "localhost,127.0.0.1,::1"
base_url = "http://localhost:11434/v1"
payload = {
    "model": "gemma4:e2b",
    "messages": [
        {"role": "system", "content": "你是一个专业的 Git 提交信息生成助手。请根据代码变更生成简洁、清晰的中文提交信息。规范要求：第一行为简短标题（不超过50字符），必须使用 Conventional Commits 前缀（feat, fix, docs, style, refactor, test, chore等），不要带多余的引号和额外解释。如果变更较多，可以分行列出要点。"},
        {"role": "user", "content": "变更摘要:\n M .env.mygit\n\n变更详情:\n diff --git a/.env.mygit b/.env.mygit\nindex 123456..789abc 100644\n--- a/.env.mygit\n+++ b/.env.mygit\n@@ -1,5 +1,6 @@\n # 您的 API 密钥\n-DASHSCOPE_API_KEY=sk-123\n+DASHSCOPE_API_KEY=ollama"}
    ]
}
try:
    print("Testing requests without proxy...")
    r = requests.post(f"{base_url}/chat/completions", json=payload, timeout=10)
    print("Content:", repr(r.json()["choices"][0]["message"]["content"]))
except Exception as e:
    print("Error:", e)
