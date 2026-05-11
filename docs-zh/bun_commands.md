# Bun 命令说明文档

本项目使用 `bun` 作为主要的包和脚本管理工具。所有在 `package.json` 中定义的脚本均已集成代理环境变量（自动加载 `scripts/get_proxy.sh`）和 Python 虚拟环境激活机制，确保网络和依赖环境的稳定性。

以下是当前项目中可用的 `bun run` 命令详解：

## 1. Git 自动化操作

**`bun run mygit`**
- **功能描述**：执行自动化的 Git 提交工作流。
- **底层行为**：检测代码变更、调用 AI 自动生成符合 Conventional Commits 规范的中文提交信息，并完成 `add -> commit -> push` 的全流程。
- **使用场景**：在完成功能开发或修复后，一键保存并推送代码到远端仓库。

**`bun run mygit:full`**
- **功能描述**：完整版 Git 提交流程（目前逻辑与 `mygit` 相同，保留作为扩展接口）。

---

## 2. Hermes Agent 核心功能

以下命令封装了对 `hermes` CLI 工具的直接调用，您可以直接在末尾追加参数使用。

**`bun run hermes [参数/子命令]`**
- **功能描述**：Hermes CLI 的通用入口。
- **使用示例**：
  - `bun run hermes --help`：查看所有可用的主命令选项。

**`bun run chat`**
- **功能描述**：启动 Hermes 交互式终端对话模式。
- **使用场景**：希望在命令行中直接与 Agent 聊天，以交互方式处理代码任务或咨询问题时使用。

**`bun run config`**
- **功能描述**：启动 Hermes 的全局配置管理面板。
- **使用场景**：用于修改大语言模型提供商 (Providers)、API 密钥设置、主题皮肤 (Skins) 或系统默认选项等环境参数。

**`bun run skills`**
- **功能描述**：启动 Hermes 技能（Skills）管理工具。
- **使用场景**：查看系统支持的所有技能、针对特定平台（如 cli、feishu 等）启用或禁用某个技能（如 `mybot`, `claude-code` 等）。

---

## 3. 服务网关管理

**`bun run gateway [子命令]`**
- **功能描述**：启动并管理 Hermes 消息平台网关服务（负责对接飞书、Telegram 等第三方通讯平台）。
- **常用组合命令**：
  - `bun run gateway run`：在前台启动网关服务并监听消息（按 `Ctrl+C` 停止）。
  - `bun run gateway run --replace`：自动清理已运行的旧网关实例并原位重启。
  - `bun run gateway restart`：后台发送重启信号，替换正在运行的网关实例。
  - `bun run gateway stop`：终止当前正在运行的网关服务。
  *(注：`bun run hermes gateway run` 是同效写法)*

---

## 4. Web 控制面板

**`bun run hermes dashboard`**
- **功能描述**：启动并访问 Hermes-Agent 的内置 Web 可视化配置面板。
- **运行机制**：该面板是一个独立的本地 Web 服务（基于 FastAPI 和 Vite/React），启动后默认监听 `http://127.0.0.1:9119`。
- **与 Gateway 的关系**：**Dashboard 和 Gateway 是两个完全独立解耦的服务**。启动 Dashboard **不会**自动启动后台的网关服务。Dashboard 仅起到监控网关状态、修改运行配置参数以及填写 API Keys 的作用。
- **使用场景**：首次使用需要填写大模型 API Key、想要通过可视化界面调整 Agent 的底层配置（无需手动改 yaml），或是查看当前 Gateway 和 Session 的监控状态时使用。如果你需要通过飞书、Telegram 等对外暴露机器人服务，仍需要单独运行 `bun run gateway start`。

---

### 技术提示：
所有的 `bun run` 脚本内部结构均采用以下统一模式：
```bash
eval $(bash scripts/get_proxy.sh) && source venv/bin/activate && <实际执行指令>
```
这保证了无论是启动网关还是调用模型接口，流量都会自动经过本机代理环境。
