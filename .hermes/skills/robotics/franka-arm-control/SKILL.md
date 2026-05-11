---
name: franka-arm-control
description: Franka 机械臂自然语言控制工具。通过 Web API 控制机械臂运动、夹爪操作和状态监控。
---

# Franka 机械臂控制

## 环境准备
- Franka API 服务器地址: http://localhost:8000
- 默认 API Key: franka-api-default-key

## 常用指令
1. 获取状态:
   - 关节状态: GET /api/v1/status/joints
   - 机器人模式: GET /api/v1/status/robot

2. 运动控制:
   - Home 位置: [0.0, -0.785, 0.0, -2.356, 0.0, 1.57, 0.785]
   - Ready 位置: [0.0, 0.0, 0.0, -1.57, 0.0, 1.57, 0.785]

3. 错误处理:
   - 错误恢复: POST /api/v1/motion/error_recovery

## 注意事项
- 执行运动前务必检查机械臂状态
- 确保紧急停止按钮可用
- 所有操作需包含 API Key 请求头