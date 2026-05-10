---
name: mybot
description: Franka 机械臂自然语言控制工具。当用户需要控制 Franka 机械臂运动、抓取物体、恢复错误或获取机器人状态时使用此技能。该技能通过调用 Franka Web API 实现对硬件的控制。
---

# Goal

通过自然语言指令精确控制 Franka 机械臂的运动和状态。

## Instructions

### 1. 环境准备
- 确保 Franka API 服务器已启动（默认地址：`http://localhost:8000`）。
- API Key 默认为 `franka-api-default-key`。

### 2. 执行步骤

#### 2.1 获取状态
在执行运动指令前，建议先获取当前状态：
- **关节状态**: `GET /api/v1/status/joints`
- **机器人模式**: `GET /api/v1/status/robot`

#### 2.2 控制运动 (PTP)
用户给出目标位置或动作描述时，将其转换为关节弧度数组：
- **接口**: `POST /api/v1/motion/move_joints`
- **常用预设**:
  - `Home`: `[0.0, -0.785, 0.0, -2.356, 0.0, 1.57, 0.785]`
  - `Ready`: `[0.0, 0.0, 0.0, -1.57, 0.0, 1.57, 0.785]`

#### 2.3 夹爪控制
- **抓取 (Grasp)**: `POST /api/v1/gripper/grasp` (需提供 width, force)
- **移动 (Move)**: `POST /api/v1/gripper/move` (需提供 width)
- **回零 (Homing)**: `POST /api/v1/gripper/homing`

#### 2.4 错误恢复
如果机器人处于错误模式，执行：
- **接口**: `POST /api/v1/motion/error_recovery`

### 3. 工具使用规范
- 使用 `curl` 或 Python `requests` 库通过 `terminal` 工具发送请求。
- 必须在 Header 中携带 `X-API-Key: franka-api-default-key`。
- 对于耗时运动，建议设置 `async_execution: true` 并通过 `task_id` 轮询状态（如果需要）。

## Examples

### 示例 1：将机械臂移动到初始位置
**用户输入**：“把机械臂复位到 Home 位置。”
**执行逻辑**：
1. 调用 `POST /api/v1/motion/move_joints`
2. Payload: `{"goal_joint_configuration": [0.0, -0.785, 0.0, -2.356, 0.0, 1.57, 0.785]}`

### 示例 2：抓取一个 4cm 宽的物体
**用户输入**：“帮我抓一下桌子上的那个小方块，大概 4 厘米宽。”
**执行逻辑**：
1. 调用 `POST /api/v1/gripper/grasp`
2. Payload: `{"width": 0.04, "speed": 0.1, "force": 50}`

## Constraints

- 严禁在未确认机器人状态的情况下执行大幅度运动。
- 运动过程中如果收到停止指令，应立即尝试中断（如果 API 支持）或记录日志。
- 所有操作结果必须以中文向用户反馈。
- 如果 API 返回错误，必须详细记录错误信息并建议用户进行 `error_recovery`。
