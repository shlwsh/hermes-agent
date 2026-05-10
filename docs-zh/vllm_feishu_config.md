# Hermes Agent 配置手册：vLLM 与飞书对接指南

本文档将详细介绍在启动项目前，如何通过配置文件设置 vLLM 连接，以及如何配置对接飞书（Feishu / Lark）平台。

---

## 一、 vLLM 连接配置

Hermes Agent 内置了对多种本地推理服务和兼容 OpenAI API 规范的终端的无缝支持。vLLM 是一个极其高效的 LLM 推理引擎，我们可以通过修改配置，将 Hermes Agent 的底层推理引擎指向您的 vLLM 服务。

### 1. 通过配置文件修改 (`config.yaml`)

在使用向导初始化后，您的核心配置文件位于 `~/.hermes/config.yaml`（或者项目的配置目录下）。您可以直接编辑该文件：

```yaml
model:
  # 设置使用 vllm（等同于 "custom" 模式，兼容 OpenAI 的调用规范）
  provider: "vllm"
  
  # vLLM 服务器的完整请求端点
  base_url: "http://<您的vllm服务器IP或域名>:8000/v1"
  
  # 默认调用的模型名称（必须与您在 vLLM 启动时指定的模型名一致）
  default: "qwen-2.5-72b-instruct"
```

*说明：vLLM 作为一个本地化或自建的模型端点，在标准的 OpenAI 接口中往往不需要严格验证 API Key，但如果您在 vLLM 前面套了一层网关认证，可以将 `OPENAI_API_KEY` 补充写入到 `~/.hermes/.env` 中。*

### 2. 通过命令行指令设置 (动态修改)

如果您不想手动修改文件，可以通过 `hermes config set` 命令行完成动态切换：

```bash
hermes config set model.provider vllm
hermes config set model.base_url http://localhost:8000/v1
hermes config set model.default "您的模型名称"
```

设置完毕后，启动 `hermes`，Agent 就会自动从 vLLM 拉取并响应模型推理内容。

---

## 二、 飞书（Feishu / Lark）平台对接

Hermes Agent 原生包含了一个高级的消息网关 (`gateway/run.py`)，允许直接接入并监听飞书机器人。飞书平台采用 WebSocket 长连接与 Webhook 的混合支持，且具备独立的安全验证能力。

### 1. 准备工作：在飞书开放平台创建应用

1. 登录 [飞书开发者后台](https://open.feishu.cn/app/)。
2. 点击 **“创建企业自建应用”**。
3. 添加 **“机器人”** 能力。
4. 在应用凭证页面获取 `App ID` 和 `App Secret`。
5. 在**“事件订阅”**页面中获取 `Encrypt Key` (加密秘钥) 和 `Verification Token`。如果是采用 **WebSocket** 长连接模式，开启长连接选项即可。

### 2. 环境变量配置 (`.env`)

所有的敏感 API 密钥与平台配置需要写入 `~/.hermes/.env` 文件（或您项目的私有环境变量配置中）。在 `.env` 中加入以下字段：

```env
# 飞书应用核心凭证
FEISHU_APP_ID="cli_a4xxxxxxxxx"
FEISHU_APP_SECRET="dGxxxxxxxxxxxxxxxxxxx"

# （可选）安全相关的 Verification Token 和 Encrypt Key
FEISHU_VERIFICATION_TOKEN="xxxxxx"
FEISHU_ENCRYPT_KEY="xxxxxx"

# 指定机器人的名字
FEISHU_BOT_NAME="HermesBot"

# (可选) 飞书的连接模式。默认是 "ws" (WebSocket，更适合内网/本地机器部署)。
# 如果您的服务器对外暴露公网，可以考虑使用 "webhook"。
FEISHU_CONNECTION_MODE="ws"

# （安全加固）限制谁可以使用该机器人，可使用逗号分隔指定人员名单
# FEISHU_ALLOWED_USERS="user1,user2"
```

### 3. 启动飞书网关

配置好所有的环境变量后，执行消息网关的启动命令：

```bash
# 启动时会自动加载 .env 的参数，并挂载飞书适配器
hermes gateway start
```

当您在终端看到 `[Gateway] Feishu websocket connected successfully` 的类似日志时，说明对接成功。

### 4. 高级能力与机制
- **长连接与重连：** Hermes 的飞书适配器默认采用 `WebSocket` 进行心跳保持，无需为 Hermes Agent 提供公网穿透域名。
- **丰富的解析支持：** 适配器自动支持解析飞书应用中的 @提及（Mentions）、富文本 (Post / Markdown)、卡片互动，以及媒体文件上传。
- **独立限流和过滤机制：** 内置了重复事件去除机制（Dedup TTL）以及针对不在白名单的群组事件自动静默。
