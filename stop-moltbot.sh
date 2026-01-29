#!/bin/bash
# Moltbot 停止脚本

PID_FILE="/tmp/moltbot-gateway.pid"

echo "🛑 停止 Moltbot..."
echo ""

# 尝试从 PID 文件获取并停止
if [ -f "$PID_FILE" ]; then
    GATEWAY_PID=$(cat "$PID_FILE")
    if ps -p "$GATEWAY_PID" > /dev/null 2>&1; then
        echo "📋 发现 Gateway 进程 (PID: $GATEWAY_PID)"
        echo "   发送 SIGTERM 信号..."
        kill -TERM "$GATEWAY_PID" 2>/dev/null || true
        
        # 等待优雅关闭
        for i in {1..10}; do
            if ! ps -p "$GATEWAY_PID" > /dev/null 2>&1; then
                echo "✓  Gateway 已停止"
                rm -f "$PID_FILE"
                break
            fi
            sleep 1
        done
        
        # 如果还在运行，强制终止
        if ps -p "$GATEWAY_PID" > /dev/null 2>&1; then
            echo "   进程未响应，强制终止..."
            kill -9 "$GATEWAY_PID" 2>/dev/null || true
            sleep 1
            if ! ps -p "$GATEWAY_PID" > /dev/null 2>&1; then
                echo "✓  Gateway 已强制停止"
            else
                echo "❌ 无法停止进程 $GATEWAY_PID"
            fi
        fi
        rm -f "$PID_FILE"
    else
        echo "⚠️  PID 文件存在，但进程 $GATEWAY_PID 不在运行"
        rm -f "$PID_FILE"
    fi
else
    echo "⚠️  未找到 PID 文件: $PID_FILE"
fi

# 清理其他可能的残留进程
echo ""
echo "🧹 清理残留进程..."
KILLED=0

# 清理所有 moltbot-gateway 进程
GATEWAY_PIDS=$(pgrep -f "moltbot-gateway" || true)
if [ -n "$GATEWAY_PIDS" ]; then
    echo "   发现 moltbot-gateway 进程: $GATEWAY_PIDS"
    for pid in $GATEWAY_PIDS; do
        kill -TERM "$pid" 2>/dev/null || true
    done
    sleep 2
    pkill -9 -f "moltbot-gateway" 2>/dev/null || true
    echo "   ✓ 清理了 moltbot-gateway 进程"
    KILLED=1
fi

# 清理 imsg 进程
IMSG_PIDS=$(pgrep -f "imsg rpc" || true)
if [ -n "$IMSG_PIDS" ]; then
    echo "   发现 imsg rpc 进程: $IMSG_PIDS"
    pkill -9 -f "imsg rpc" 2>/dev/null || true
    echo "   ✓ 清理了 imsg rpc 进程"
    KILLED=1
fi

# 清理 Mac app
if pkill -KILL -f "Moltbot" 2>/dev/null; then
    echo "   ✓ 清理了 Moltbot app"
    KILLED=1
fi

if [ $KILLED -eq 0 ]; then
    echo "   ✓ 没有发现残留进程"
fi

# 清理端口占用
echo ""
echo "🔌 检查端口占用..."
if lsof -i :18789 > /dev/null 2>&1; then
    echo "   端口 18789 被占用，正在清理..."
    lsof -ti :18789 | xargs kill -9 2>/dev/null || true
    sleep 1
    echo "   ✓ 端口已释放"
else
    echo "   ✓ 端口 18789 未被占用"
fi

# 等待资源释放
echo ""
echo "⏳ 等待资源释放..."
sleep 3

echo ""
echo "✅ 停止完成！"
echo ""
echo "💡 验证: ps aux | grep -E '[m]oltbot|[i]msg'"
echo "💡 检查端口: lsof -i :18789"
echo ""
