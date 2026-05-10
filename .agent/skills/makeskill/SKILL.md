---
name: makeskill
description: Skill 制作工具。当用户需要为项目创建新的 Skill（技能）时使用此技能。根据规范自动生成标准目录结构和 SKILL.md 模板，确保产出符合 Antigravity Skill 架构要求。
---

# Goal

帮助用户快速创建符合 Antigravity 规范的 Skill 技能文件夹，包含标准目录结构和格式化的 `SKILL.md` 文件，降低技能制作门槛。

## Instructions

### 1. 收集信息

在创建 Skill 之前，需要向用户确认以下信息（如果用户未提供）：

| 参数 | 是否必填 | 说明 |
|------|---------|------|
| `skill-name` | ✅ 必填 | 技能名称，小写字母 + 中划线，如 `my-custom-skill` |
| `description` | ✅ 必填 | 技能描述，说明适用场景和触发条件 |
| `goal` | ✅ 必填 | 技能的最终目标，一句话概括 |
| `scope` | 可选 | 存放级别：`project`（项目级，默认）或 `global`（全局级） |
| `has-scripts` | 可选 | 是否需要 `scripts/` 目录，默认 `false` |
| `has-examples` | 可选 | 是否需要 `examples/` 目录，默认 `true` |
| `has-resources` | 可选 | 是否需要 `resources/` 目录，默认 `false` |

### 2. 确定存放路径

根据 `scope` 参数决定技能的存储位置：

- **项目级（默认）**：`<项目根目录>/.agent/skills/<skill-name>/`
- **全局级**：`~/.gemini/antigravity/skills/<skill-name>/`

### 3. 创建目录结构

创建以下标准目录结构：

```text
.agent/skills/<skill-name>/
├── SKILL.md            # [必选] 技能核心定义文件
├── examples/           # [可选] 输入/输出示例文件
├── scripts/            # [可选] 自动化脚本
└── resources/          # [可选] 静态资源或参考数据
```

仅创建用户需要的可选目录。

### 4. 生成 SKILL.md

`SKILL.md` 必须包含以下部分，严格遵循格式：

#### 4.1 YAML 元数据（Frontmatter）

```yaml
---
name: <skill-name>
description: <description>
---
```

> **关键点：** `description` 是触发器，必须清晰描述该技能的**适用场景**，包含"当用户...时使用此技能"的句式。

#### 4.2 核心内容块

按以下标题顺序组织内容：

1. **`# Goal`**：一句话说明技能的最终目标
2. **`## Instructions`**：详细的操作步骤和逻辑判断
   - 使用编号列表描述步骤
   - 包含条件判断和分支处理
   - 引用外部脚本时使用相对路径
3. **`## Examples`**：1-3 个"输入→输出"示例（Few-shot prompting）
   - 每个示例包含：场景描述、输入、预期输出
   - 示例应覆盖正常流程、异常处理、边界情况
4. **`## Constraints`**：明确列出禁止行为和限制条件

### 5. 生成示例文件（可选）

如果启用了 `examples/` 目录，为每个示例创建独立的 Markdown 文件：

- 命名格式：`01-<场景描述>.md`、`02-<场景描述>.md`
- 内容包含：场景说明、完整输入、完整输出

### 6. 生成脚本文件（可选）

如果启用了 `scripts/` 目录：

- 脚本应包含 `--help` 选项，便于 Agent 黑盒调用
- 在 `SKILL.md` 的 Instructions 中说明："若脚本运行失败，请阅读脚本内容并尝试修复"
- 脚本中使用相对路径，确保可移植性

### 7. 质量检查

创建完成后，执行以下检查：

1. ✅ `SKILL.md` 存在且包含有效的 YAML Frontmatter
2. ✅ `name` 字段为小写 + 中划线格式
3. ✅ `description` 字段包含明确的触发场景描述
4. ✅ `# Goal`、`## Instructions`、`## Constraints` 三个必要章节齐全
5. ✅ 所有文件路径引用使用相对路径
6. ✅ 示例覆盖正常流程和至少一种异常场景

## Examples

### 输入 1：创建简单技能

用户说："帮我创建一个 skill，名称是 code-review，用于自动审查代码质量。"

**执行过程：**

1. 收集参数：`skill-name=code-review`，`scope=project`
2. 创建目录：`.agent/skills/code-review/`
3. 生成文件

**输出目录结构：**

```text
.agent/skills/code-review/
├── SKILL.md
└── examples/
    ├── 01-normal-review.md
    └── 02-no-issues.md
```

**生成的 SKILL.md 示例：**

```markdown
---
name: code-review
description: 代码质量审查工具。当用户需要审查代码质量、检查潜在问题、或执行代码评审时使用此技能。自动扫描代码变更，分析潜在问题，并生成结构化的审查报告。
---

# Goal

自动审查代码变更的质量，识别潜在问题并生成结构化的审查报告。

## Instructions

1. 获取待审查的代码文件或变更范围
2. 按以下维度进行审查：
   - 代码规范性（命名、格式、注释）
   - 逻辑正确性（边界条件、错误处理）
   - 性能影响（复杂度、资源使用）
   - 安全风险（注入、泄露、权限）
3. 生成审查报告，按严重程度分类

## Examples

### 输入 1：审查一个 Vue 组件
...

## Constraints

- 不得自动修改源代码，仅提供审查建议
- 审查报告必须使用中文
- 不记录或输出敏感信息（密钥、密码等）
```

### 输入 2：创建带脚本的技能

用户说："创建一个 db-backup 技能，需要包含备份脚本，放在全局级别。"

**执行过程：**

1. 收集参数：`skill-name=db-backup`，`scope=global`，`has-scripts=true`
2. 创建目录：`~/.gemini/antigravity/skills/db-backup/`
3. 生成文件，包含 `scripts/` 目录和脚本模板

**输出目录结构：**

```text
~/.gemini/antigravity/skills/db-backup/
├── SKILL.md
├── examples/
│   └── 01-full-backup.md
└── scripts/
    └── backup.sh
```

### 输入 3：参数不完整

用户说："创建一个新技能。"

**执行过程：**

向用户询问必填信息：

```text
需要以下信息来创建技能：

1. **技能名称**（skill-name）：小写字母 + 中划线格式，如 `my-skill`
2. **技能描述**（description）：该技能的适用场景和触发条件
3. **技能目标**（goal）：一句话说明要实现的最终目标

可选配置：
- 是否需要 scripts/ 目录？（默认：否）
- 是否需要 resources/ 目录？（默认：否）
- 存放级别：项目级（默认）还是全局级？
```

## Constraints

- 技能名称必须使用小写字母和中划线，禁止使用大写、空格或特殊字符
- `SKILL.md` 必须包含有效的 YAML Frontmatter（`name` 和 `description` 字段）
- `description` 字段必须包含明确的触发场景描述
- 所有文件引用必须使用相对路径，确保跨环境可移植
- 禁止在技能文件中包含敏感信息（API 密钥、密码等）
- 禁止创建与已有技能同名的目录（应先提示用户确认是否覆盖）
- 每个 Skill 遵循单一职责原则，只做一件事
- `SKILL.md` 内容必须使用中文编写
