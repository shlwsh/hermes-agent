# Hermes Agent 项目技术与使用手册

## 一、 项目概述

**Hermes Agent** 是由 [Nous Research](https://nousresearch.com) 开发的一款具备自我持续优化能力的 AI 智能体。它突破了传统本地客户端的局限，不仅能在命令行终端中提供功能丰富的 TUI 界面，还支持通过消息网关（Telegram、Discord、Slack 等）实现跨平台、分布式的交互与执行。它具备自主学习、技能编排、定时任务、沙箱后端执行等企业级能力。

---

## 二、 技术架构

本项目整体遵循模块化、高可扩展性的设计原则，其核心目录结构和模块划分为：

### 1. 核心智能体模块 (`run_agent.py` & `agent/`)
- **`AIAgent` 类**：项目的心脏模块。封装了与 LLM 服务（OpenRouter、Anthropic 等）的同步交互循环。
- **Agent Internals**：
  - `prompt_builder.py`: 动态组装系统 Prompt。
  - `context_compressor.py`: 自动化上下文压缩引擎。
  - `prompt_caching.py`: 优化大规模对话时的 Prompt 缓存。

### 2. 交互与平台网关
- **CLI 命令行引擎 (`cli.py` & `hermes_cli/`)**：
  - 基于 `prompt_toolkit` 构建带自动补全的交互式控制台。
  - **Skin Engine (`skin_engine.py`)**：数据驱动的终端 UI 主题引擎，支持自定义颜色、加载动画（KawaiiSpinner）和工具前缀。
  - **指令解析中心 (`commands.py`)**：统一管控全局 `/` 斜杠命令（如 `/model`、`/skills`），支持动态别名。
- **消息网关 (`gateway/`)**：
  - 核心事件循环 (`run.py`) 及 Session 管理器。
  - 各大平台适配器 (`platforms/`): 负责对接 Telegram、Discord、Slack、WhatsApp、Signal 等。

### 3. 工具与技能生态 (`tools/`)
- **Tool Registry (`registry.py`)**：采用装饰器/注册模式集中管理各工具的 Schema、依赖检查及执行句柄。
- **沙盒与执行器**：
  - `code_execution_tool.py`: 提供代码沙盒运行环境。
  - `delegate_tool.py`: 支持创建隔离的 Subagent 子智能体，完成并行任务。
  - `environments/`: 支持将代码和命令派发到本地、Docker、SSH、Daytona、Singularity 及 Modal 无服务器后端运行。

---

## 三、 核心工作流程

1. **配置加载与配置隔离 (Profiles)**：
   - 系统支持多实例（Profiles）。在启动时会通过 `hermes_constants.py` 动态重载 `HERMES_HOME` 环境变量，实现配置、会话记录和缓存的彻底隔离。
2. **对话与工具调度闭环 (Agent Loop)**：
   - 接收用户输入并注入上下文 → 组装 System Prompt → 发送请求至 LLM。
   - 检测到工具调用（Tool Calls）时，在 `model_tools.py` 统一拦截 → 寻找对应的后端执行器（如 Docker 或远端环境）。
   - 将工具执行结果以 JSON 格式拼接至对话历史，进入下一轮迭代，直至任务完成并输出给用户。
3. **自我改进机制 (Self-Improvement)**：
   - Agent 自动捕捉异常（Exit code != 0）、用户纠正及更优方案，记录在 `.learnings/`。
   - 当同一模式的教训触发次数超过阈值，会自动提炼规则并“晋升”至全局项目记忆（如 `AGENTS.md`）。

---

## 四、 核心功能特性

- **模型自由切换**：内置兼容 OpenAI API 规范的调用机制，支持一键切换上百种模型（`/model`）。
- **真正的全平台协同**：从手机 Telegram 提交任务，它会在云端 VPS 上的 Docker 中自动执行并实时汇报。
- **定时与自动化流 (Cron)**：内置计划任务调度器，支持通过自然语言设置诸如“每晚备份系统”或“每周五发送报告”的任务。
- **技能自生成机制 (Skill System)**：在复杂任务完成后，能自动总结并封装出具备独立触发条件和步骤逻辑的 Skill，供后续无缝复用。

---

## 五、 配置说明

系统的配置文件存放于专属的 `HERMES_HOME` 目录下（默认为 `~/.hermes/`）：

1. **`config.yaml`（运行配置）**：
   - 控制工具集白名单、UI 皮肤(`display.skin`)、终端输出格式等。
2. **`.env`（密钥与环境配置）**：
   - 存放各个大模型服务商的 API Keys。
   - 存放不同消息平台（如 Telegram Bot Token）的凭据。
   - 工具使用所需的环境变量（例：`DASHSCOPE_API_KEY` 等）。
3. **修改方式**：
   - 可直接编辑文件，也可通过交互式命令修改：`hermes config set <key> <value>`。

---

## 六、 启动与部署

### 快速安装
Linux、macOS 推荐使用一键安装脚本（自动处理依赖与虚拟环境）：
```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
source ~/.bashrc
```

### 开发者源码部署
```bash
git clone https://github.com/shlwsh/hermes-agent.git
cd hermes-agent
# 推荐使用 uv 管理依赖
curl -LsSf https://astral.sh/uv/install.sh | sh
uv venv venv --python 3.11
source venv/bin/activate
uv pip install -e ".[all,dev]"
```

### 常用运行指令
- **启动交互式 CLI**：
  ```bash
  hermes
  ```
- **启动跨平台消息网关**（例如对接 Telegram）：
  ```bash
  hermes gateway start
  ```
- **系统向导与诊断**：
  ```bash
  hermes setup    # 初始化向导（涵盖 API 配置、网关开启等）
  hermes doctor   # 诊断环境与网络连通性
  hermes update   # 自动升级最新版本
  ```

> **注意：** 在向项目添加底层修改、开发新工具或扩展 Agent 能力时，请务必参考项目根目录下的 `AGENTS.md` 开发者指南。
