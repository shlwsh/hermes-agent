---
name: restore-knowledge
description: 知识大脑恢复工具。将项目 knowledges 目录下的沉淀知识点增量恢复到系统全局专属知识大脑目录中。
---

# 目标 (Goal)
当您在全新的机器上拉取了代码仓库，或是通过仓库同步获得了团队其他人的专属知识库时，通过此工作流，将项目级保管的 `knowledges` 目录以**增量**的方式重新注入到系统的全局专属大脑中，激活 AI 的项目领域记忆。

# 执行步骤 (Instructions)

## 1. 检查源数据
- **源路径 (Source)**：当前项目的 `knowledges/` 目录。
- **检查**：使用 `run_command` 检查该目录是否存在以及是否包含数据。如果不存在或为空，向用户报告没有可恢复的知识。

## 2. 明确目标路径
- **目标路径 (Destination)**：`/home/smz/.gemini/antigravity/knowledge/`
  - *(注：若执行环境变更，请从系统提供的 `<user_information>` 中提取当前的 App Data 目录)*

## 3. 执行增量恢复
// turbo
- 使用 `run_command` 工具执行同步。
- ⚠️ **至关重要**：恢复操作必须是**增量**的。不能使用 `--delete` 参数，以防覆盖或销毁您在当前本地计算机中已经创建且未同步的其他私人知识项目：
  ```bash
  mkdir -p /home/smz/.gemini/antigravity/knowledge/
  rsync -av ./knowledges/ /home/smz/.gemini/antigravity/knowledge/
  ```

## 4. 统计与汇报
- 执行成功后，向用户反馈增量恢复已完成。
- 可以顺带列出恢复后您的专属大脑中现在拥有哪些类别的知识。
