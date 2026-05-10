import os
import subprocess
import sys
import requests
import json
from datetime import datetime

def run_command(command, check=True):
    """执行 shell 命令并返回输出"""
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if check and result.returncode != 0:
        return None
    return result.stdout.strip()

def get_wsl_proxy():
    """自动检测 WSL 中的宿主机代理"""
    try:
        host_ip = run_command("ip route show | grep default | awk '{print $3}'")
        if host_ip:
            for port in ["7897", "7890", "1080"]:
                if run_command(f"nc -zv {host_ip} {port} 2>&1") is not None:
                    return f"http://{host_ip}:{port}"
    except:
        pass
    return None

def main():
    print("🚀 AI Git 提交工具启动 (Python 版)")
    
    # 自动设置代理
    proxy_url = get_wsl_proxy()
    if proxy_url:
        print(f"📡 检测到宿主机代理: {proxy_url}")
        os.environ["http_proxy"] = proxy_url
        os.environ["https_proxy"] = proxy_url
        os.environ["all_proxy"] = proxy_url
        os.environ["HTTP_PROXY"] = proxy_url
        os.environ["HTTPS_PROXY"] = proxy_url
        os.environ["ALL_PROXY"] = proxy_url
    else:
        # 如果没检测到，且当前环境变量包含 127.0.0.1 代理，则清理
        for var in ["http_proxy", "https_proxy", "HTTP_PROXY", "HTTPS_PROXY", "all_proxy", "ALL_PROXY"]:
            val = os.environ.get(var, "")
            if "127.0.0.1" in val or "localhost" in val:
                del os.environ[var]

    # 1. 验证 Git 仓库
    if run_command("git rev-parse --git-dir") is None:
        print("❌ 错误: 当前目录不是一个有效的 Git 仓库")
        sys.exit(1)

    # 2. 加载配置
    env_file = ".env.mygit"
    if not os.path.exists(env_file):
        print(f"❌ 错误: 找不到配置文件 {env_file}")
        print("请确保项目根目录下存在该文件。")
        sys.exit(1)

    config = {}
    try:
        with open(env_file, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#"):
                    if "=" in line:
                        key, value = line.split("=", 1)
                        config[key.strip()] = value.strip().strip("'").strip('"')
    except Exception as e:
        print(f"❌ 错误: 读取配置文件失败: {e}")
        sys.exit(1)

    api_key = config.get("DASHSCOPE_API_KEY")
    base_url = config.get("DASHSCOPE_BASE_URL", "").rstrip("/")
    model = config.get("DASHSCOPE_MODEL")

    if not all([api_key, base_url, model]):
        print("❌ 错误: 配置文件中缺少必填项 (DASHSCOPE_API_KEY, DASHSCOPE_BASE_URL, DASHSCOPE_MODEL)")
        sys.exit(1)

    # 3. 检测变更
    print("📝 正在检查代码变更...")
    status_output = run_command("git status --porcelain")
    if not status_output:
        print("✅ 没有检测到代码变更")
        sys.exit(0)

    changes = status_output.split("\n")
    print(f"发现 {len(changes)} 个文件变更：")
    for line in changes:
        print(f"  {line}")

    # 4. 版本文件检测
    version_files = ["package.json", "pyproject.toml", "src-tauri/tauri.conf.json", "src-tauri/Cargo.toml"]
    if any(any(vf in line for vf in version_files) for line in changes):
        print("\n⚠️ 检测到版本相关文件变更，建议使用相关的版本发布命令 (如 bun run release:tag)")

    # 5. 生成提交信息
    print("\n🤖 正在使用 AI 生成提交信息...")
    commit_msg = ""
    try:
        # 暂存所有变更以获取 diff
        subprocess.run("git add .", shell=True, check=True)
        diff_content = run_command("git diff --cached")
        if diff_content and len(diff_content) > 10000:
            diff_content = diff_content[:10000] + "... (Diff truncated)"

        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}"
        }
        payload = {
            "model": model,
            "messages": [
                {"role": "system", "content": "你是一个专业的 Git 提交信息生成助手。请根据代码变更生成简洁、清晰的中文提交信息。规范要求：第一行为简短标题（不超过50字符），必须使用 Conventional Commits 前缀（feat, fix, docs, style, refactor, test, chore等），不要带多余的引号和额外解释。如果变更较多，可以分行列出要点。"},
                {"role": "user", "content": f"变更摘要:\n{status_output}\n\n变更详情:\n{diff_content}"}
            ],
            "max_tokens": 500,
            "temperature": 0.7
        }

        # 使用 requests 发送请求，增加超时时间
        response = requests.post(f"{base_url}/chat/completions", headers=headers, json=payload, timeout=60)
        response.raise_for_status()
        
        data = response.json()
        commit_msg = data["choices"][0]["message"]["content"].strip()
        
        # 移除 markdown 代码块
        if commit_msg.startswith("```"):
            lines = commit_msg.split("\n")
            if lines[0].startswith("```"):
                lines = lines[1:]
            if lines and lines[-1].startswith("```"):
                lines = lines[:-1]
            commit_msg = "\n".join(lines).strip()

    except Exception as e:
        print(f"⚠️ AI 生成提交信息失败 ({e})，正在使用托底逻辑...")
        today = datetime.now().strftime("%Y-%m-%d")
        commit_msg = f"chore: 自动同步代码变更 ({today})\n\n变更摘要：\n{status_output}\n\n由于 AI 生成失败，此信息由系统自动生成。"

    print("\n提交信息：")
    print("──────────────────────────────────────────────────")
    print(commit_msg)
    print("──────────────────────────────────────────────────\n")

    # 8. 提交
    print("💾 正在创建提交...")
    msg_file = ".git/COMMIT_MSG_TMP"
    with open(msg_file, "w", encoding="utf-8") as f:
        f.write(commit_msg)
    try:
        subprocess.run(f"git commit -F {msg_file} --no-verify", shell=True, check=True)
    except Exception as e:
        print(f"❌ 提交失败: {e}")
        sys.exit(1)
    finally:
        if os.path.exists(msg_file):
            os.remove(msg_file)

    # 9. 推送
    print("🚀 正在推送到远程仓库...")
    
    # 使用当前设置的环境变量执行 push
    env = os.environ.copy()

    try:
        branch = run_command("git rev-parse --abbrev-ref HEAD")
        remote = run_command(f"git config branch.{branch}.remote") or "origin"
        has_upstream = run_command(f"git config branch.{branch}.merge")

        if not has_upstream:
            print(f"📡 远程仓库: {remote}, 分支: {branch} (首次推送)")
            subprocess.run(f"git push --set-upstream {remote} {branch} --no-verify", shell=True, env=env, check=True)
        else:
            print(f"📡 远程仓库: {remote}, 分支: {branch}")
            subprocess.run("git push --no-verify", shell=True, env=env, check=True)
        print("\n✨ 提交并推送成功！")
    except Exception as e:
        print(f"\n❌ 推送失败: {e}")
        print("本地提交已保留，你可以手动执行 git push --no-verify")

if __name__ == "__main__":
    main()
