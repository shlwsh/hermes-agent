---
name: bak-knowledge
description: 知识大脑备份工具。将个人的全局专属知识大脑目录（~/.gemini/antigravity/knowledge）全面备份并同步到当前项目的 knowledges 目录下，方便将知识库纳入项目的版本控制。
---

# 目标 (Goal)
将位于系统层面的全局 AI 专属知识库同步备份到项目内的 `knowledges` 目录中。这使得有价值的架构记录、排错经验能够作为项目的一部分与代码仓库一并托管，避免重装系统或迁移环境导致的知识丢失。

# 执行步骤 (Instructions)

## 1. 明确路径
- **源路径 (Source)**：`/home/smz/.gemini/antigravity/knowledge/`
  - *(注：若执行环境变更，请从系统提供的 `<user_information>` 中提取当前的 App Data 目录)*
- **目标路径 (Destination)**：当前项目的 `knowledges/` 目录。

## 2. 执行备份同步
// turbo
- 使用 `run_command` 工具调用系统命令，创建一个精确同步的备份。推荐使用带有 `--delete` 参数的 `rsync`，以确保项目内的备份能实时反映知识库的当前状态（同步删除失效知识）：
  ```bash
  mkdir -p ./knowledges
  rsync -av --delete /home/smz/.gemini/antigravity/knowledge/ ./knowledges/
  ```

## 3. 统计与汇报
- 备份完成后，统计当前同步了多少个知识工件（KI 数量即为子目录数量）。
- 提示用户备份已经准备好，并且可以运行相关的 git 命令或自动化脚本（如 `mygit.sh`）将这些知识点归档至远程代码仓库。
