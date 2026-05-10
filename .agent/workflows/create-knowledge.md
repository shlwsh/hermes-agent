---
name: create-knowledge
description: 当用户输入 /create-knowledge 或请求从当前会话提取知识点时，调用此工作流。自动提取本会话中的踩坑经验、解决方案或架构设计，严格按照 Antigravity 知识引擎标准生成 Knowledge Item (KI)，存入 AI 专属知识大脑目录中。
---

# 目标 (Goal)
将当前会话中产生的核心经验、配置方法、代码规范或报错解决等高价值信息，提炼并封装为标准的 Knowledge Item (KI)，持久化存入专属知识库，以便跨会话复用。

# 执行步骤 (Instructions)

## 1. 确定知识主题与内容提取
- **回顾当前会话**，提炼出 1-3 个有复用价值的核心知识点。
- **梳理背景**：问题现象、应用场景或设计初衷。
- **梳理根因**：为什么会发生该问题或为什么要这么设计。
- **梳理解决方案**：具体操作命令、代码改动或架构选择，提供明确可执行的步骤。
- **生成唯一标识 ID**：根据主题生成一个英文及短横线组成的字符串，作为 KI 的目录名（如 `hermes-skin-fix`）。

## 2. 定位系统知识库路径
系统知识库存储在全局 App Data 目录下。
- **App Data Directory**: 始终从你接收到的系统提示信息 `<persistent_context>` 或 `<user_information>` 中提取当前的 App Data 路径（通常为 `~/.gemini/antigravity` 等形式）。
- **KI 存储路径**：`<appDataDir>/knowledge/<ki-id>/`
  - 核心元数据：`<appDataDir>/knowledge/<ki-id>/metadata.json`
  - 详细文档：`<appDataDir>/knowledge/<ki-id>/artifacts/knowledge.md`

## 3. 生成知识工件文件 (artifacts/knowledge.md)
使用 `write_to_file` 工具写入 `artifacts/knowledge.md`，内容需采用结构化 Markdown 编写，推荐使用以下格式：
```markdown
# [知识标题]

## 背景与问题描述
描述遇到此问题的场景或设计背景。

## 根因分析
深度剖析导致问题产生的根本原因。

## 解决方案 / 最佳实践
提供具体的修复步骤、代码示例或最佳实践要求。
```

## 4. 生成元数据文件 (metadata.json)
使用 `write_to_file` 工具生成 `metadata.json` 文件，严格采用以下结构：
```json
{
  "title": "<简短且有描述性的中文标题>",
  "summary": "<一到两句话的摘要，包含核心关键词>",
  "timestamps": {
    "created": "<当前会话时间，例如：2026-05-10T06:00:00+08:00>",
    "updated": "<同 created>"
  },
  "references": [
    "<涉及的关键文件路径或相关工具名称，如 /scripts/mygit.sh>"
  ]
}
```

## 5. 向用户确认
操作完成后，向用户报告：
- 生成的知识库标题
- KI 存储的确切绝对路径
- 简短的摘要说明

# 约束与注意事项 (Constraints)
- 严禁将底层知识项直接写入项目代码目录（如 `docs/` 或 `sessions/`），必须写入 `<appDataDir>/knowledge/`。
- `metadata.json` 必须是合法的 JSON 格式。
- 知识项的提取应当聚焦于“经验沉淀”和“通用配置”，不要包含一次性的无用 debug 日志或无价值的流水账。
