---
name: mygit
description: AI 智能 Git 提交工具。当用户需要提交代码、推送代码、同步代码、git commit、git push、推送变更、代码提交、代码推送、保存并提交、提交到仓库、或执行 `bun run mygit` 时使用此技能。自动检测代码变更，调用 AI 生成中文 Conventional Commits 格式的提交信息，并一键完成 add → commit → push 流程。
---

# Goal

自动化 Git 提交流程：检测代码变更 → 调用 AI 生成中文提交信息 → `git add` → `git commit` → `git push`，一条命令完成全部操作。

## Instructions

### 1. 环境准备

确保以下前置条件满足：

1. 项目根目录下存在 `.env.mygit` 配置文件（格式参见 `resources/env.mygit.template`）
2. 配置文件中的三个必填字段不为空：`DASHSCOPE_API_KEY`、`DASHSCOPE_BASE_URL`、`DASHSCOPE_MODEL`
3. 当前目录为有效的 Git 仓库

### 2. 执行命令

```bash
# 简化版（推荐日常使用）
bun run mygit

# 完整版（含交互式编辑、diff 分析等高级功能）
bun run mygit:full
```

### 3. 执行流程

脚本按以下步骤顺序执行：

1. **加载配置**：从 `.env.mygit` 读取 AI API 密钥、地址和模型名称
2. **验证 Git 仓库**：执行 `git rev-parse --git-dir`
3. **检测变更**：执行 `git status --porcelain`，解析出新增/修改/删除的文件列表
4. **版本文件检测**：若变更包含 `package.json`、`pyproject.toml`，提示用户改用相关发布脚本进行版本发布
5. **AI 生成提交信息**：
   - 调用 OpenAI 兼容 API（`POST {baseUrl}/chat/completions`）
   - System Prompt：`你是一个专业的 Git 提交信息生成助手。请根据代码变更生成简洁、清晰的中文提交信息。`
   - 用户消息包含变更摘要和文件列表
   - 参数：`max_tokens=300`，`temperature=0.7`
6. **托底逻辑**：若 AI 调用失败，自动生成 `chore: 自动同步代码变更 (YYYY-MM-DD)` 格式的提交信息
7. **暂存**：`git add .`
8. **提交**：`git commit -m "提交信息" --no-verify`
9. **推送**：
   - 自动检测当前分支和远程仓库
   - 自动检测 `http_proxy`/`HTTP_PROXY` 环境变量配置代理
   - 执行 `git push --no-verify`
   - 首次推送时自动 `--set-upstream`

### 4. AI 配置说明

| 配置项 | 环境变量名 | 说明 |
|-------|-----------|------|
| API 密钥 | `DASHSCOPE_API_KEY` | 阿里云 DashScope 平台密钥 |
| API 地址 | `DASHSCOPE_BASE_URL` | OpenAI 兼容接口地址 |
| 模型名称 | `DASHSCOPE_MODEL` | 推荐 `deepseek-v3` |

可用模型：`deepseek-v3`（默认）、`deepseek-v3.2-exp`、`deepseek-r1`、`qwen-vl-plus`

### 5. 提交信息生成规则

AI 被要求按以下规则生成提交信息：

1. 使用中文
2. 第一行为简短标题（不超过 50 字符）
3. 使用 Conventional Commits 前缀：`feat` / `fix` / `docs` / `style` / `refactor` / `test` / `chore`
4. 描述清晰、准确

### 6. 脚本执行失败处理

若脚本运行失败，请按以下步骤排查：

1. 检查 `.env.mygit` 文件是否存在且配置正确
2. 检查网络连接和 API 密钥有效性
3. 若 AI 调用失败，脚本会自动降级使用托底提交信息
4. 若推送失败，本地提交仍然保留，可手动执行 `git push --no-verify`
5. 若仍无法解决，请阅读 `scripts/mygit-simple.ts` 源码定位问题

## Examples

### 输入 1：正常提交

用户执行 `bun run mygit`，有 3 个文件变更。

**输出：**

```text
🚀 AI Git 提交工具启动

📝 正在检查代码变更...

发现 3 个文件变更：
  修改: run_agent.py
  修改: cli.py
  新增: tools/mygit_tool.py

🤖 正在使用 AI 生成提交信息...

提交信息：
──────────────────────────────────────────────────
feat: 支持 AI 辅助的 Git 提交流程

- 新增 mygit_tool 模块以实现代码自动提交
- 修改 cli.py 和 run_agent.py 以适配该工具
──────────────────────────────────────────────────

📦 正在添加变更到暂存区...
💾 正在创建提交...
🚀 正在推送到远程仓库...
📡 远程仓库: origin, 分支: dev0319

✨ 提交并推送成功！
```

### 输入 2：AI 调用失败，自动降级

API 返回 429 错误。

**输出：**

```text
⚠️  AI 生成提交信息失败 (API 请求失败: 429)，正在使用托底逻辑生成简介...

提交信息：
──────────────────────────────────────────────────
chore: 自动同步代码变更 (2026-03-19)

变更摘要：
- 修改 2 个文件
- 新增 1 个文件

由于 AI 生成失败，此信息由系统自动生成。
──────────────────────────────────────────────────
```

### 输入 3：无代码变更

当前工作区干净，无待提交内容。

**输出：**

```text
🚀 AI Git 提交工具启动

📝 正在检查代码变更...
✅ 没有检测到代码变更
```

## Constraints

- `.env.mygit` 包含 API 密钥，**严禁提交到 Git 仓库**（已在 `.gitignore` 中排除）
- 禁止在无变更时执行提交
- 提交和推送均使用 `--no-verify` 跳过 Husky hooks
- 版本号相关文件变更时，必须提示用户使用 `bun run release:tag` 而非直接提交
- 禁止修改 `.env.mygit` 中用户已配置的 API 密钥
- 禁止在日志或输出中打印完整的 API 密钥
