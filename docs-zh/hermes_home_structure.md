# Hermes 默认配置目录 (`.hermes`) 详细结构解读

`HERMES_HOME` 是 Hermes Agent 运行的核心状态、配置与数据存储根目录。在本项目中，该目录默认被映射到项目源码根目录下的 `.hermes` 文件夹（即 `/home/smz/projects/hermes-agent/.hermes`），从而实现了配置的项目级隔离。

以下是 `.hermes` 目录及其核心文件的全层级详细解读：

## 1. 核心配置文件与环境

*   **`.env`**: 环境变量与核心凭证文件。包含各大模型提供商的 API Key（如 OpenAI, Anthropic）、通信平台的 Bot Token（如 Telegram, Slack）、自定义网络代理等敏感信息。
*   **`config.yaml`**: Hermes Agent 核心应用配置文件。定义了界面的主题外观（Skin）、默认使用的模型参数、功能开关、以及底层代理等全局配置。
*   **`SOUL.md`**: Agent 核心人格与“灵魂”设定文件（Core System Prompt）。决定了 AI 回复的基础逻辑、语言习惯、底层目标等，类似于全局指导方针。

## 2. 数据库与持久化状态

*   **`state.db`** (及其辅文件 `state.db-wal`, `state.db-shm`): 基于 SQLite 的持久化会话数据库（SessionDB），支持 FTS5 搜索。存储全局配置、交互检索的上下文。
*   **`sessions/`**: 历史会话存档目录。
    *   `session_*.json`: 单独保存的每个交互会话的完整上下文（消息列表、使用的工具状态等）。
    *   `*.jsonl`: 对话轮次的流式数据追加日志，主要用于数据分析与训练。
    *   `sessions.json`: 全局会话索引。
*   **`memories/`**: Agent 的“大脑”长期记忆库。
    *   `MEMORY.md`: AI 在交互过程中自主提取和总结的关键知识点、项目约束或长期记忆。
    *   `USER.md`: 用户画像与偏好记录，确保 AI 能跨越不同的 Session 持续理解用户的专属开发习惯（如本项目的“中文优先”和“Bun 工具”等规范）。

## 3. 技能库与模型缓存

*   **`skills/`**: Hermes Skills（能力插件）的核心存放区。每个子目录代表一个专属技能模块（如项目刚集成的 `mybot`，以及内置的 `software-development`, `devops`, `creative` 等），内部通过 `SKILL.md` 驱动 Agent 调用专用工具流。
*   **`.skills_prompt_snapshot.json`**: 当前所有已启用技能的系统提示词（System Prompt）映射快照，用于缓存以提高对话启动速度并降低 Token 计算成本。
*   **`models_dev_cache.json`**: AI 模型目录/元数据的本地缓存文件，避免频繁查询提供商（如 OpenRouter 等）的 API 限制与上下文长度上限。
*   **`auth.json` / `auth.lock`**: 不同底层 LLM 接口及辅助服务的自动鉴权和互斥锁缓存。

## 4. 后台网关与运行状态 (Gateway)

*   **`gateway_state.json`**: 记录后台网关（Hermes Gateway）当前运行的数据结构（如哪些通信平台处于 Active 状态）。
*   **`gateway.pid`**: 网关守护进程（Daemon）的唯一进程 ID 文件。执行 `hermes gateway restart/stop` 时，会通过该文件定位并管理后台进程。
*   **`channel_directory.json`**: 映射和跟踪第三方消息平台（如 Feishu、Telegram 等）的频道与用户 ID，实现群组环境中的消息准确投递。

## 5. 日志与隔离环境

*   **`logs/`**: 系统运行日志的存放目录。
    *   `agent.log`: Agent 核心执行过程与模型调用的详细日志，追踪工具分发流程（如为何未能成功触发特定 API）。
    *   `errors.log`: 单独抽离的异常/报错日志。
*   **`sandboxes/`**: 本地隔离执行环境的缓存空间（如内含 `singularity/` 目录），确保 `execute_code` 技能在安全可控的容器或沙盒中运行 Python/Bash 代码。
*   **`cron/`**: 定时任务调度器目录。内部包含 `.tick.lock` （防止重入调度）以及 `output/` （存放定时任务的运行输出结果）。

## 6. 其他基础目录

*   **`cache/`**: 存放 Hermes 抓取的数据、图片等零散临时文件。
*   **`migration/`**: 当更新 Hermes 核心代码并触发 `state.db` 的版本升级时，相应的数据库迁移脚本与备份文件会被放置在此。
*   **`platforms/`**: 与各类消息平台专属的挂载资源目录。
*   **`bin/`**: 预留用于放置某些受支持的第三方二进制执行依赖。

---

**总结**：`.hermes` 不仅是一个配置文件存放处，更是 Agent 的“本体数据中心”。它集成了从系统设定、技能扩展，到长短期记忆、会话日志、后台状态管理的一整套 Agent 工作流依赖。通过将其默认放置在项目根目录，既实现了当前项目的多环境隔离，也大幅提升了部署的移植便利性。
