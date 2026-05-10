# 飞书（Feishu / Lark）对接配置完全指南

本文档详细介绍 Hermes Agent 与飞书（Feishu / Lark）平台对接的配置机制、路径加载原理，以及如何将配置目录指向项目本地目录。

---

## 一、 配置路径体系

### 1.1 Hermes Home 目录

Hermes Agent 的所有运行时数据（配置、会话、缓存、日志等）默认存放在 `~/.hermes/` 目录下。该路径由以下函数统一管理：

```python
# hermes_constants.py
def get_hermes_home() -> Path:
    return Path(os.getenv("HERMES_HOME", Path.home() / ".hermes"))
```

**核心规则：**
- 默认路径：`~/.hermes/`
- 通过环境变量 `HERMES_HOME` 可重定向到任意目录
- 路径解析逻辑对所有模块（`gateway/`、`agent/`、`tools/` 等）完全透明

### 1.2 `~/.hermes/` 目录结构

| 文件 / 目录 | 用途 |
|---|---|
| `config.yaml` | 主配置文件：模型提供商、工具集、会话策略等 |
| `.env` | 环境变量：API Keys、平台凭证等敏感信息 |
| `sessions/` | 对话历史与上下文压缩缓存 |
| `skills/` | 同步的技能（Skills）文件 |
| `logs/` | 运行日志 |
| `profiles/` | 多配置 Profile（用于隔离不同项目） |
| `feishu_seen_message_ids.json` | 飞书消息去重状态文件 |
| `.clean_shutdown` | 干净退出标记（用于判断是否跳过会话挂起） |

### 1.3 配置文件加载优先级

配置从高到低的加载优先级如下：

```
环境变量（HERMES_HOME 指向的配置）
    ↓
~/.hermes/config.yaml      （主配置文件）
    ↓
~/.hermes/gateway.json     （遗留格式，向上合并）
    ↓
代码内置默认值
```

---

## 二、 将配置目录指向项目本地（HERMES_HOME）

### 2.1 适用场景

- 在多个项目中隔离各自独立的 Hermes 配置
- 将配置纳入 Git 管理（配合 `.gitignore` 忽略敏感字段）
- 在 Docker / 容器环境中指定持久化路径

### 2.2 方法一：环境变量（推荐）

在启动命令前设置环境变量即可，无需修改任何代码：

```bash
# 方式 A：相对路径（以启动目录为基准）
HERMES_HOME="$(pwd)/.hermes" hermes gateway run

# 方式 B：绝对路径
HERMES_HOME="/home/smz/projects/my-project/.hermes" hermes gateway run
```

**首次初始化：**

```bash
mkdir -p .hermes
hermes setup       # 交互式向导，配置写入 .hermes/
hermes gateway run
```

### 2.3 方法二：Profile 机制（项目命名配置）

将项目配置目录注册为命名 Profile，通过 `--profile` 参数快速切换：

```bash
# 创建 Profile 软链接
mkdir -p .hermes
ln -s /home/smz/projects/my-project/.hermes ~/.hermes/profiles/my-project

# 启动时使用 -p 指定
hermes -p my-project gateway run
```

`--profile` 机制在 CLI 启动时将对应目录路径写入 `HERMES_HOME` 环境变量，效果与方法一完全一致，且无需每次输入环境变量。

### 2.4 方法三：写入项目 `.env`（仅限已加载 .env 的命令）

如果项目根目录存在 `.env` 文件（Hermes CLI 启动时会加载），可在其中写入：

```env
HERMES_HOME=/home/smz/projects/my-project/.hermes
```

### 2.5 设置默认 HERMES_HOME（全局生效）

对于长期使用项目目录作为默认配置位置，可以修改 shell 配置文件：

```bash
# 在 ~/.bashrc 或 ~/.zshrc 中添加
export HERMES_HOME="/home/smz/projects/hermes-agent/.hermes"
```

---

## 三、 飞书平台对接配置

### 3.1 准备工作：在飞书开放平台创建应用

1. 登录 [飞书开发者后台](https://open.feishu.cn/app/)。
2. 点击 **「创建企业自建应用」**。
3. 进入 **「应用能力」→「机器人」**，添加机器人能力。
4. 在 **「凭证与基础信息」** 页面获取：
   - `App ID`（格式：`cli_xxxxxxxx`）
   - `App Secret`
5. 在 **「事件订阅」** 页面：
   - **WebSocket 模式**：开启长连接选项
   - **Webhook 模式**：获取 `Encrypt Key` 和 `Verification Token`

### 3.2 环境变量配置（`.env`）

将以下配置写入 `~/.hermes/.env`（或项目 `.hermes/.env`）：

```env
# ── 飞书应用核心凭证（必需）────────────────────────────
FEISHU_APP_ID="cli_a4xxxxxxxxx"
FEISHU_APP_SECRET="dGxxxxxxxxxxxxxxxxxxx"

# ── 区域 / 域名（可选，默认为飞书中国）────────────────
# feishu：飞书中国（open.feishu.cn）
# lark  ：Lark 国际版（open.larksuite.com）
FEISHU_DOMAIN="feishu"

# ── 连接模式（可选，默认为 websocket）──────────────────
# websocket：推荐，适合本地/内网部署，无需公网地址
# webhook ：需公网可访问的 HTTP 端点
FEISHU_CONNECTION_MODE="websocket"

# ── 安全验证（Webhook 模式下强烈建议配置）────────────
FEISHU_VERIFICATION_TOKEN="xxxxxx"
FEISHU_ENCRYPT_KEY="xxxxxx"

# ── Webhook 模式服务器配置（Webhook 模式下适用）──────
FEISHU_WEBHOOK_HOST="127.0.0.1"
FEISHU_WEBHOOK_PORT="8765"
FEISHU_WEBHOOK_PATH="/feishu/webhook"

# ── 机器人身份（可选，用于群聊 @mention 精确识别）─────
FEISHU_BOT_NAME="HermesBot"
FEISHU_BOT_OPEN_ID="ou_xxxxxxxx"
FEISHU_BOT_USER_ID="xxxxxxxx"

# ── 用户访问控制──────────────────────────────────────
# 逗号分隔的飞书 Open ID 白名单
# FEISHU_ALLOWED_USERS="ou_xxx,ou_yyy"
# 允许所有用户私聊机器人
# FEISHU_ALLOW_ALL_USERS="true"

# ── 群组策略（可选，默认为 allowlist）────────────────
# open     ：响应所有 @mention
# allowlist：仅响应白名单用户（需配置 FEISHU_ALLOWED_USERS）
# disabled ：忽略所有群消息
FEISHU_GROUP_POLICY="allowlist"

# ── 家庭频道（可选）：定时任务结果发送目标 ───────────
FEISHU_HOME_CHANNEL="oc_xxxxxxxx"
```

### 3.3 WebSocket 模式详解

WebSocket 是推荐的连接方式，具有以下优势：

| 优势 | 说明 |
|---|---|
| 无需公网地址 | Hermes 主动建立出站连接，不依赖入站 webhook |
| 自动重连 | SDK 内置指数退避重连，网络抖动自动恢复 |
| 心跳保持 | 自动维护连接活性 |

**初始连接超时处理：** 首次连接时若遇网络超时（`timed out during opening handshake`），SDK 会自动重试 3 次，通常在 2–3 分钟内恢复，无需手动干预。

### 3.4 Webhook 模式配置

Webhook 模式需要服务器有公网可达地址：

```env
FEISHU_CONNECTION_MODE="webhook"
FEISHU_WEBHOOK_HOST="0.0.0.0"
FEISHU_WEBHOOK_PORT="8765"
```

飞书开发者后台配置订阅地址为：
```
http://<你的服务器IP>:8765/feishu/webhook
```

### 3.5 启动网关

```bash
# 标准启动
hermes gateway run

# 指定项目配置目录
HERMES_HOME="$(pwd)/.hermes" hermes gateway run

# 或使用 Profile
hermes -p my-project gateway run
```

启动成功日志示例：

```
[Lark] [2026-05-10 18:15:17,038] [INFO] connected to wss://msg-frontier.feishu.cn/ws/v2?...
gateway.platforms.feishu: [Feishu] Connected in websocket mode (feishu)
```

---

## 四、 飞书应用权限配置

部分功能需要额外的权限范围（Permission Scopes）。在飞书开放平台 → 你的应用 → **权限管理** 中申请：

### 4.1 必需权限

| 权限 | 用途 | 影响功能 |
|---|---|---|
| `im:message` | 读取消息内容 | 消息接收与解析 |
| `im:message:send_as_bot` | 发送消息 | 机器人回复 |
| `im:chat:readonly` 或 `im:chat` | 读取群组信息 | 获取群名称、成员等元数据 |

**申请地址（直接跳转）：**
```
https://open.feishu.cn/app/cli_a931706059b95bde/auth?q=im:chat:readonly,im:chat,im:chat:read&op_from=openapi&token_type=tenant
```

> 注意替换 `cli_a931706059b95bde` 为你的实际 App ID。

### 4.2 可选权限（增强体验）

| 权限 | 用途 | 影响功能 |
|---|---|---|
| `im:message.reactions:write_only` | 添加表情回应 | ACK 表情（已读确认） |
| `admin:app.info:readonly` 或 `application:application:self_manage` | 读取应用信息 | 精确 @mention 机器人识别 |

---

## 五、 常见错误与排查

### 5.1 `processor not found, type: im.chat.access_event.bot_p2p_chat_entered_v1`

**原因：** 飞书新版事件类型未在事件处理器中注册。
**状态：** 此问题已在 Hermes Agent 最新版本中修复（`gateway/platforms/feishu.py`），重启网关即可。

### 5.2 `[Feishu] Access denied. One of the following scopes is required: im:chat:readonly`

**原因：** 飞书应用缺少必需权限范围。
**解决：** 在飞书开放平台申请对应权限后，发布新版本（应用版本需审核或管理员审批）。

### 5.3 `Unable to hydrate bot identity from application info`

**原因：** 应用未配置 `admin:app.info:readonly` 或 `application:application:self_manage` 权限。
**影响：** 仅影响群聊中 @mention 的精确识别，不影响核心消息收发功能。
**解决：** 在飞书开放平台申请权限并发布新版本。

### 5.4 `connect failed, err: timed out during opening handshake`

**原因：** 网络连接不稳定（首次连接时常见）。
**状态：** SDK 已内置自动重连（最多 3 次，指数退避），通常自动恢复。

### 5.5 `no close frame received or sent` / `keepalive ping timeout`

**原因：** WebSocket 连接因网络中断或飞书服务端主动断开。
**状态：** SDK 会自动重连，无需手动干预。
**优化：** 如频繁出现，可调整以下参数（见 3.2 节）：
```env
HERMES_FEISHU_WS_RECONNECT_INTERVAL=120
HERMES_FEISHU_WS_PING_INTERVAL=30
```

---

## 六、 交互式配置向导

除了手动编辑 `.env`，也可以使用交互式向导配置飞书：

```bash
hermes gateway setup
```

选择 **Feishu / Lark**，向导会提供两种创建方式：

1. **扫码创建（推荐）：** 用飞书 App 扫描二维码，自动创建应用并配置权限
2. **手动输入：** 输入已有的 `App ID` 和 `App Secret`

配置完成后，向导自动将凭证写入 `~/.hermes/.env`。

---

## 七、 完整配置示例（项目本地目录）

假设项目目录为 `/home/smz/projects/hermes-agent/`，以下是一套完整的本地化配置流程：

```bash
# 1. 创建本地配置目录
mkdir -p /home/smz/projects/hermes-agent/.hermes

# 2. 在 .env 中写入飞书凭证
cat > /home/smz/projects/hermes-agent/.hermes/.env << 'EOF'
FEISHU_APP_ID="cli_a4xxxxxxxxx"
FEISHU_APP_SECRET="dGxxxxxxxxxxxxxxxxxxx"
FEISHU_DOMAIN="feishu"
FEISHU_CONNECTION_MODE="websocket"
FEISHU_BOT_NAME="HermesBot"
EOF

# 3. 启动网关（指定 HERMES_HOME）
cd /home/smz/projects/hermes-agent
HERMES_HOME="$(pwd)/.hermes" hermes gateway run

# 4. 如需设为默认（写入 shell 配置）
echo 'export HERMES_HOME="/home/smz/projects/hermes-agent/.hermes"' >> ~/.bashrc
source ~/.bashrc
```

> **安全提示：** 将 `.hermes/.env` 中的 `FEISHU_APP_SECRET` 加入 `.gitignore`，避免凭证泄露到版本控制中：
> ```gitignore
> .hermes/.env
> .hermes/sessions/
> .hermes/logs/
> ```
