---
name: mybot
description: Franka 机械臂自然语言控制工具。当用户需要控制 Franka 机械臂运动、抓取物体、恢复错误或获取机器人状态时使用此技能。该技能通过调用 Franka Web API 实现对硬件的控制。
---

# Goal

通过自然语言指令精确控制 Franka 机械臂的运动和状态。

## Instructions

### 0. 核心行为准则（最高优先级）

**你必须立即使用 `terminal` 工具执行 curl 命令。严禁将 curl 命令以代码块或 JSON 形式展示给用户。**

- ❌ **错误做法**：在回复中展示 `curl` 命令或 JSON 代码块，然后询问用户"是否执行"
- ✅ **正确做法**：直接调用 `terminal` 工具，以 `curl` 命令作为参数立即执行，然后根据执行结果向用户反馈

**用户发送指令即代表授权执行，不需要二次确认。** 收到用户的运动指令后，应当立即执行，不要等待用户说"执行"或"确认"。

### 1. 环境准备
- Franka API 服务器地址：`http://localhost:8000`
- API Key：`franka-api-default-key`
- 当前运行在仿真 (Fake Hardware) 模式

### 2. 执行流程

当用户要求执行运动指令时，按以下流程操作：

**步骤 1**：直接调用 `terminal` 工具执行运动指令，**不要**先查询状态或执行错误恢复。

**步骤 2**：根据 API 返回结果向用户反馈（中文）。

#### 2.1 控制运动 (PTP)
用户给出目标位置或动作描述时，将其转换为关节弧度数组：
- **接口**: `POST /api/v1/motion/move_joints`
- **常用预设**:
  - `Home`: `[0.0, -0.785, 0.0, -2.356, 0.0, 1.57, 0.785]`
  - `Ready`: `[0.0, 0.0, 0.0, -1.57, 0.0, 1.57, 0.785]`

#### 2.2 夹爪控制
- **抓取 (Grasp)**: `POST /api/v1/gripper/grasp` (需提供 width, force)
- **移动 (Move)**: `POST /api/v1/gripper/move` (需提供 width)
- **回零 (Homing)**: `POST /api/v1/gripper/homing`

#### 2.3 获取状态（仅在用户明确要求时）
- **关节状态**: `GET /api/v1/status/joints`
- **机器人模式**: `GET /api/v1/status/robot`

#### 2.4 错误恢复（仅在真实硬件报错时）
- **接口**: `POST /api/v1/motion/error_recovery`
- 仿真模式下此接口不可用，忽略即可。

## Examples

### 示例 1：将机械臂移动到初始位置
**用户输入**："把机械臂复位到 Home 位置。"
**你必须立即执行**（不是展示代码）：
```
调用 terminal 工具，command 参数为：
curl -s -X POST http://localhost:8000/api/v1/motion/move_joints -H "X-API-Key: franka-api-default-key" -H "Content-Type: application/json" -d '{"goal_joint_configuration": [0.0, -0.785, 0.0, -2.356, 0.0, 1.57, 0.785]}'
```
然后根据返回结果告诉用户执行情况。

### 示例 2：抓取一个 4cm 宽的物体
**用户输入**："帮我抓一下桌子上的那个小方块，大概 4 厘米宽。"
**你必须立即执行**：
```
调用 terminal 工具，command 参数为：
curl -s -X POST http://localhost:8000/api/v1/gripper/grasp -H "X-API-Key: franka-api-default-key" -H "Content-Type: application/json" -d '{"width": 0.04, "speed": 0.1, "force": 50}'
```

## Constraints

- **直接执行，不要询问确认**。用户的指令就是执行授权。
- 所有操作结果必须以中文向用户反馈。
- 仿真模式下 `"No robot state received yet"` 和 `"Error Recovery Action Server not available"` 都是正常现象，忽略即可。
- 如果运动 API 返回成功（如 `"Goal accepted"`），告诉用户指令已发送，机械臂正在运动。
- 如果运动 API 返回失败，告诉用户具体错误并建议检查 API 服务器。
