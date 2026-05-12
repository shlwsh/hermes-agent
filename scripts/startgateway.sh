#!/bin/bash
# ─────────────────────────────────────────────────────────
# startgateway.sh — 清理旧进程并重启 Hermes Gateway 服务
# 用法: bun run startgateway
# ─────────────────────────────────────────────────────────

set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$(pwd)/.hermes}"
PID_FILE="$HERMES_HOME/gateway.pid"

echo "🔄 Hermes Gateway 重启工具"
echo "──────────────────────────────────────────────────"

# ── 1. 检测并设置代理 ────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_EXPORTS=$(bash "$SCRIPT_DIR/get_proxy.sh" 2>/dev/null || true)
if [ -n "$PROXY_EXPORTS" ]; then
    eval "$PROXY_EXPORTS"
fi

# ── 2. 激活虚拟环境 ──────────────────────────────────────
source venv/bin/activate 2>/dev/null || {
    echo "⚠️  未找到 venv，跳过虚拟环境激活"
}

# ── 3. 清理旧的 Gateway 进程 ─────────────────────────────
cleanup_old_gateway() {
    # 3a. 从 PID 文件获取旧进程
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(python3 -c "
import json, sys
try:
    data = json.load(open('$PID_FILE'))
    pid = data.get('pid') if isinstance(data, dict) else int(data)
    print(pid)
except:
    sys.exit(1)
" 2>/dev/null || cat "$PID_FILE" 2>/dev/null | grep -oP '\d+' | head -1)

        if [ -n "$OLD_PID" ]; then
            if kill -0 "$OLD_PID" 2>/dev/null; then
                echo "⏹️  正在停止旧 Gateway 进程 (PID: $OLD_PID)..."
                kill "$OLD_PID" 2>/dev/null || true
                # 等待进程退出，最多 5 秒
                for i in $(seq 1 10); do
                    if ! kill -0 "$OLD_PID" 2>/dev/null; then
                        echo "✅ 旧进程已停止"
                        break
                    fi
                    sleep 0.5
                done
                # 如果还没退出，强制杀掉
                if kill -0 "$OLD_PID" 2>/dev/null; then
                    echo "⚠️  进程未响应 SIGTERM，强制终止..."
                    kill -9 "$OLD_PID" 2>/dev/null || true
                    sleep 0.5
                    echo "✅ 进程已强制终止"
                fi
            else
                echo "ℹ️  PID 文件存在但进程已不在运行 (PID: $OLD_PID)"
            fi
        fi
        rm -f "$PID_FILE"
    fi

    # 3b. 扫描残留的 gateway 进程
    REMAINING=$(pgrep -f "hermes.*gateway.*run" 2>/dev/null | grep -v "$$" || true)
    if [ -n "$REMAINING" ]; then
        echo "🧹 发现残留 Gateway 进程，正在清理..."
        echo "$REMAINING" | while read pid; do
            kill "$pid" 2>/dev/null || true
        done
        sleep 1
        # 再次检查并强制清理
        STILL_ALIVE=$(pgrep -f "hermes.*gateway.*run" 2>/dev/null | grep -v "$$" || true)
        if [ -n "$STILL_ALIVE" ]; then
            echo "$STILL_ALIVE" | while read pid; do
                kill -9 "$pid" 2>/dev/null || true
            done
            sleep 0.5
        fi
        echo "✅ 残留进程已清理"
    fi

    # 3c. 清理 scoped locks
    LOCK_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hermes/gateway-locks"
    if [ -d "$LOCK_DIR" ]; then
        rm -f "$LOCK_DIR"/*.lock 2>/dev/null || true
        echo "🔓 已清理 Gateway 锁文件"
    fi
}

cleanup_old_gateway

echo "──────────────────────────────────────────────────"
echo "🚀 正在启动 Hermes Gateway..."
echo ""

# ── 4. 启动新的 Gateway ──────────────────────────────────
exec hermes gateway run
