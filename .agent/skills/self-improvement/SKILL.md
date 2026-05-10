---
name: self-improvement
description: 持续自我改进工具。当以下情况发生时使用此技能：(1) 命令或操作意外失败；(2) 用户纠正 Agent（如"不对"、"实际上应该..."）；(3) 用户请求不存在的功能；(4) 外部 API 或工具调用失败；(5) 发现自身知识过时或错误；(6) 发现了更好的方案。在执行重要任务前也应回顾已有学习记录。
---

# Goal

让 Agent 在日常工作中自动捕捉错误、纠正和最佳实践，通过结构化记录和渐进式晋升机制实现持续自我改进。

## Instructions

### 1. 检测学习触发点

在日常交互中，主动识别以下信号：

| 信号类型 | 触发关键词/场景 | 记录目标 |
|---------|---------------|---------|
| 用户纠正 | "不对"、"实际上应该..."、"你搞错了" | `.learnings/LEARNINGS.md`（分类：`correction`） |
| 命令失败 | 非零退出码、异常堆栈、超时 | `.learnings/ERRORS.md` |
| 功能缺失 | "能不能..."、"有没有办法..."、"为什么不能..." | `.learnings/FEATURE_REQUESTS.md` |
| 知识过时 | 用户提供了 Agent 不知道的信息、文档已过时 | `.learnings/LEARNINGS.md`（分类：`knowledge_gap`） |
| 更优方案 | 发现了比初始方案更好的做法 | `.learnings/LEARNINGS.md`（分类：`best_practice`） |

### 2. 结构化记录

检测到触发信号后，按以下格式追加到对应日志文件。

#### 2.1 学习条目（LEARNINGS.md）

```markdown
## [LRN-YYYYMMDD-XXX] 分类

**Logged**: ISO-8601 时间戳
**Priority**: low | medium | high | critical
**Status**: pending
**Area**: frontend | backend | infra | tests | docs | config

### 摘要
一行描述学到了什么

### 详情
完整上下文：发生了什么、错在哪里、正确做法是什么

### 建议操作
具体的修复或改进措施

### 元数据
- 来源: conversation | error | user_feedback
- 相关文件: path/to/file
- 标签: tag1, tag2
- 关联条目: LRN-20250110-001（如有关联）
- Pattern-Key: simplify.dead_code（可选，用于模式追踪）
- Recurrence-Count: 1（可选）

---
```

#### 2.2 错误条目（ERRORS.md）

```markdown
## [ERR-YYYYMMDD-XXX] 命令或技能名

**Logged**: ISO-8601 时间戳
**Priority**: high
**Status**: pending
**Area**: frontend | backend | infra | tests | docs | config

### 摘要
简要描述什么失败了

### 错误信息
```
实际的错误消息或输出
```

### 上下文
- 执行的命令/操作
- 使用的输入或参数
- 相关环境信息

### 建议修复
如果能识别，描述可能的解决方案

### 元数据
- 可复现: yes | no | unknown
- 相关文件: path/to/file
- 关联条目: ERR-20250110-001（如反复出现）

---
```

#### 2.3 功能请求条目（FEATURE_REQUESTS.md）

```markdown
## [FEAT-YYYYMMDD-XXX] 功能名称

**Logged**: ISO-8601 时间戳
**Priority**: medium
**Status**: pending
**Area**: frontend | backend | infra | tests | docs | config

### 请求的功能
用户想要做什么

### 用户上下文
为什么需要，要解决什么问题

### 复杂度估计
simple | medium | complex

### 建议实现
如何构建，可能扩展什么现有功能

### 元数据
- 频率: first_time | recurring
- 相关功能: 已有功能名

---
```

### 3. ID 生成規则

格式：`TYPE-YYYYMMDD-XXX`
- TYPE: `LRN`（学习）、`ERR`（错误）、`FEAT`（功能请求）
- YYYYMMDD: 当前日期
- XXX: 顺序编号或 3 位随机字符（如 `001`、`A7B`）

### 4. 关联与去重

记录新条目前，先搜索是否已有类似条目：

```powershell
# PowerShell（Windows）
Select-String -Path .learnings/*.md -Pattern "关键词"
```

```bash
# Bash（Linux/macOS）
grep -r "关键词" .learnings/
```

- 如有关联，添加 `关联条目: ERR-20250110-001`
- 如反复出现，提高 Priority
- 使用 `Pattern-Key` 和 `Recurrence-Count` 追踪重复模式

### 5. 条目状态管理

| 状态 | 含义 |
|------|------|
| `pending` | 尚未处理 |
| `in_progress` | 正在处理中 |
| `resolved` | 问题已修复或知识已整合 |
| `wont_fix` | 决定不处理（需注明原因） |
| `promoted` | 已晋升到项目记忆 |
| `promoted_to_skill` | 已提取为独立技能 |

修复后更新条目：
```markdown
### 解决记录
- **Resolved**: 2025-01-16T09:00:00Z
- **Commit/PR**: abc123 或 #42
- **Notes**: 简要描述做了什么
```

### 6. 晋升机制

当学习条目满足以下条件时，晋升到项目级记忆文件：

**晋升条件（满足任一）：**
- 跨多个文件/功能适用
- 任何贡献者（人类或 AI）都应该知道的知识
- 能防止反复犯错
- 记录了项目特定的约定

**晋升目标：**

| 学习类型 | 晋升到 | 示例 |
|---------|--------|------|
| 项目约定和事实 | `AGENTS.md` | "包管理器用 bun 不是 npm" |
| 工作流改进 | `AGENTS.md` | "API 变更后需运行 codegen" |
| 行为模式 | `AGENTS.md` | "简洁回答，避免免责声明" |
| 工具注意事项 | `AGENTS.md` | "Git push 前需先配置认证" |

**自动晋升规则（Simplify & Harden）：**

当同一 Pattern-Key 满足以下全部条件时触发自动晋升：
1. `Recurrence-Count >= 3`（至少出现 3 次）
2. 出现在 ≥ 2 个不同任务中
3. 在 30 天窗口内

**晋升操作：**
1. 将学习内容提炼为简洁的规则
2. 添加到对应的目标文件
3. 更新原条目状态为 `promoted`

### 7. 定期审查

在以下时间点主动回顾 `.learnings/`：

- 开始新的重要任务前
- 完成一个功能后
- 在有历史学习记录的领域工作时

**快速检查命令：**

```powershell
# PowerShell（Windows）
# 统计待处理项
(Select-String -Path .learnings/*.md -Pattern 'Status\*\*: pending').Count

# 列出高优先级待处理项
Select-String -Path .learnings/*.md -Pattern 'Priority\*\*: high' -Context 5,0 | Select-String '## \['

# 查找特定领域的学习
(Select-String -Path .learnings/*.md -Pattern 'Area\*\*: backend' -List).Filename
```

```bash
# Bash（Linux/macOS）
# 统计待处理项
grep -h "Status\*\*: pending" .learnings/*.md | wc -l

# 列出高优先级待处理项
grep -B5 "Priority\*\*: high" .learnings/*.md | grep "^## \["

# 查找特定领域的学习
grep -l "Area\*\*: backend" .learnings/*.md
```

### 8. 优先级指南

| 优先级 | 适用场景 |
|--------|---------|
| `critical` | 阻塞核心功能、数据丢失风险、安全问题 |
| `high` | 重大影响、常见工作流受影响、反复出现 |
| `medium` | 中等影响、有变通方案 |
| `low` | 轻微不便、边界情况、锦上添花 |

### 9. 领域标签

| 领域 | 范围 |
|------|------|
| `frontend` | UI、组件、客户端代码 |
| `backend` | API、服务、服务端代码 |
| `infra` | CI/CD、部署、Docker、云服务 |
| `tests` | 测试文件、测试工具、覆盖率 |
| `docs` | 文档、注释、README |
| `config` | 配置文件、环境变量、设置 |

## Examples

### 示例 1：记录命令错误

**场景**：执行 `npm install` 失败，因为项目使用 bun。

**输入**：Agent 运行 `npm install`，终端输出错误信息。

**输出**：Agent 在 `.learnings/ERRORS.md` 末尾追加：

```markdown
## [ERR-20260323-001] npm_install

**Logged**: 2026-03-23T10:30:00+08:00
**Priority**: medium
**Status**: pending
**Area**: config

### 摘要
npm install 失败，项目使用 bun 而非 npm

### 错误信息
```
npm ERR! code ENOLOCK
npm ERR! This command requires an existing lockfile.
```

### 上下文
- 执行的命令: npm install
- 项目根目录存在 bun.lockb
- 应使用 bun install

### 建议修复
检测到 bun.lockb 时使用 bun install，而非 npm install

### 元数据
- 可复现: yes
- 相关文件: bun.lockb, package.json
- 标签: 包管理器, bun, npm

---
```

### 示例 2：记录用户纠正

**场景**：Agent 生成了使用 `axios` 的代码，用户纠正说项目统一使用 `fetch`。

**输入**：用户说"不要用 axios，我们这个项目统一用 fetch"。

**输出**：Agent 在 `.learnings/LEARNINGS.md` 末尾追加：

```markdown
## [LRN-20250323-001] correction

**Logged**: 2025-03-23T11:00:00+08:00
**Priority**: high
**Status**: pending
**Area**: frontend

### 摘要
项目 HTTP 请求统一使用 fetch API，不使用 axios

### 详情
在生成 API 调用代码时使用了 axios 库。用户纠正指出项目的 HTTP 请求约定
统一使用原生 fetch API，不引入第三方 HTTP 客户端。

### 建议操作
1. 在本项目中生成 HTTP 请求代码时统一使用 fetch
2. 考虑将此规则晋升到 AGENTS.md

### 元数据
- 来源: user_feedback
- 相关文件: src/api/
- 标签: HTTP, fetch, 项目约定

---
```

随后考虑是否晋升到 `AGENTS.md`（因为这是全项目约定）。

### 示例 3：晋升学习到项目记忆

**场景**：同一个 Pattern-Key 已出现 3 次，满足自动晋升条件。

**输入**：Agent 发现 `Pattern-Key: config.env_load_order` 的 `Recurrence-Count` 达到 3。

**输出**：

1. 在 `AGENTS.md` 中添加：
```markdown
## 配置约定
- 环境变量加载顺序: .env.local > .env.{mode} > .env，不要覆盖 .env.local 中的值
```

2. 更新原学习条目：
```markdown
**Status**: promoted
**Promoted**: AGENTS.md
```

## Constraints

- 条目 ID 必须唯一，格式严格遵循 `TYPE-YYYYMMDD-XXX`
- 记录必须**立即**进行——上下文在事件发生后最新鲜
- 每条记录必须包含**具体的修复建议**，不能只写"待调查"
- 禁止在学习文件中记录敏感信息（API 密钥、密码、Token 等）
- 晋升到项目记忆时必须**提炼为简洁规则**，而非冗长的事件描述
- 关联已有条目时必须先搜索，避免重复记录
- 所有文件路径使用相对路径，确保跨环境可移植
- `.learnings/` 目录下的文件使用中文记录
