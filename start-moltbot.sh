#!/bin/bash
# Moltbot 完整启动脚本（从 Terminal.app 运行）

# PID 文件路径
PID_FILE="/tmp/moltbot-gateway.pid"

echo "🚀 启动 Moltbot..."
echo ""

# 1. 确保在正确的目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
echo "📁 工作目录: $SCRIPT_DIR"
echo ""

# 2. 设置环境变量
echo "🔑 设置环境变量..."
export CLAWDBOT_GATEWAY_TOKEN="${CLAWDBOT_GATEWAY_TOKEN:-local-dev-token}"
echo "   Token: ${CLAWDBOT_GATEWAY_TOKEN:0:8}..."

# 设置代理（VPN 环境）
export HTTP_PROXY="http://127.0.0.1:7890"
export HTTPS_PROXY="http://127.0.0.1:7890"
export http_proxy="http://127.0.0.1:7890"
export https_proxy="http://127.0.0.1:7890"
echo "   Proxy: 127.0.0.1:7890"
echo ""

# 3. 停止所有现有进程
echo "📋 停止现有进程..."

# 先尝试从 PID 文件获取并优雅地停止
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "   发现现有 Gateway (PID: $OLD_PID)，正在优雅停止..."
        kill -TERM "$OLD_PID" 2>/dev/null || true
        # 等待优雅关闭
        for i in {1..10}; do
            if ! ps -p "$OLD_PID" > /dev/null 2>&1; then
                echo "   ✓ Gateway 已停止"
                break
            fi
            sleep 1
        done
        # 如果还在运行，强制杀死
        if ps -p "$OLD_PID" > /dev/null 2>&1; then
            echo "   进程未响应，强制终止..."
            kill -9 "$OLD_PID" 2>/dev/null || true
            sleep 1
        fi
    fi
    rm -f "$PID_FILE"
fi

# 清理所有相关进程（更彻底）
echo "   清理所有相关进程..."

# 找到所有 moltbot-gateway 进程
GATEWAY_PIDS=$(pgrep -f "moltbot-gateway" || true)
if [ -n "$GATEWAY_PIDS" ]; then
    echo "   发现 moltbot-gateway 进程: $GATEWAY_PIDS"
    for pid in $GATEWAY_PIDS; do
        kill -TERM "$pid" 2>/dev/null || true
    done
    sleep 2
    # 强制清理残留
    pkill -9 -f "moltbot-gateway" 2>/dev/null || true
fi

# 清理 imsg 进程
IMSG_PIDS=$(pgrep -f "imsg rpc" || true)
if [ -n "$IMSG_PIDS" ]; then
    echo "   发现 imsg 进程: $IMSG_PIDS"
    pkill -9 -f "imsg rpc" 2>/dev/null || true
fi

# 清理 Mac app 进程
pkill -KILL -f "Moltbot" 2>/dev/null || true

# 额外等待，确保所有文件描述符都被释放
echo "   等待资源释放..."
sleep 5

# 验证清理
REMAINING=$(pgrep -f "moltbot-gateway|imsg rpc" || true)
if [ -n "$REMAINING" ]; then
    echo "   ⚠️  仍有残留进程: $REMAINING"
    echo "   尝试强制清理..."
    kill -9 $REMAINING 2>/dev/null || true
    sleep 2
fi
echo "   ✓ 进程清理完成"
echo ""

# 4. 确保 Node service 正在运行
echo "📋 检查 Node service..."
if ! moltbot node status 2>/dev/null | grep -q "running"; then
    echo "⚠️  Node service 未运行，正在启动..."
    launchctl bootstrap gui/$UID ~/Library/LaunchAgents/bot.molt.node.plist 2>/dev/null || true
    sleep 2
    # 再次验证
    if moltbot node status 2>/dev/null | grep -q "running"; then
        echo "✓  Node service 启动成功"
    else
        echo "⚠️  Node service 启动失败，但继续尝试启动 Gateway"
    fi
else
    echo "✓  Node service 正在运行"
fi
echo ""

# 5. 启动 Gateway
echo "🌐 启动 Gateway..."

# 检查端口是否被占用
if lsof -i :18789 > /dev/null 2>&1; then
    echo "⚠️  端口 18789 被占用，正在清理..."
    lsof -ti :18789 | xargs kill -9 2>/dev/null || true
    sleep 2
fi

# 清空旧日志和临时文件
> /tmp/moltbot-gateway.log
rm -rf /tmp/moltbot/*.sock 2>/dev/null || true

# 确保工作目录正确
echo "   工作目录: $(pwd)"
echo "   Token: ${CLAWDBOT_GATEWAY_TOKEN:0:8}..."

# 启动 Gateway 并保存 PID（显式传递代理环境变量）
nohup env \
    HTTP_PROXY="http://127.0.0.1:7890" \
    HTTPS_PROXY="http://127.0.0.1:7890" \
    http_proxy="http://127.0.0.1:7890" \
    https_proxy="http://127.0.0.1:7890" \
    CLAWDBOT_GATEWAY_TOKEN="$CLAWDBOT_GATEWAY_TOKEN" \
    pnpm moltbot gateway run --bind loopback --port 18789 --force > /tmp/moltbot-gateway.log 2>&1 &
GATEWAY_PID=$!
echo "$GATEWAY_PID" > "$PID_FILE"
echo "   Gateway PID: $GATEWAY_PID (保存到 $PID_FILE)"
echo "   等待 Gateway 初始化..."
sleep 3

# 检查 Gateway 是否成功启动
if ! ps -p $GATEWAY_PID > /dev/null 2>&1; then
    echo "❌ Gateway 进程已退出！查看日志："
    echo ""
    echo "=== 完整日志 ==="
    cat /tmp/moltbot-gateway.log
    echo "==============="
    echo ""
    rm -f "$PID_FILE"
    exit 1
fi
echo "✓  Gateway 进程运行中"
echo ""

# 等待 Gateway 完全就绪
echo "⏳ 等待 Gateway 就绪..."
READY=0
for i in {1..15}; do
    sleep 2
    
    # 检查进程是否还活着
    if ! ps -p $GATEWAY_PID > /dev/null 2>&1; then
        echo ""
        echo "❌ Gateway 在启动过程中崩溃！查看日志："
        echo ""
        echo "=== 完整日志 ==="
        cat /tmp/moltbot-gateway.log
        echo "==============="
        echo ""
        rm -f "$PID_FILE"
        exit 1
    fi
    
    # 检查是否有错误
    if grep -q "EBADF\|ELIFECYCLE\|Command failed" /tmp/moltbot-gateway.log 2>/dev/null; then
        echo ""
        echo "❌ Gateway 启动出错！查看日志："
        echo ""
        echo "=== 错误日志 ==="
        grep -A 5 "EBADF\|ELIFECYCLE\|Command failed\|Error:" /tmp/moltbot-gateway.log || cat /tmp/moltbot-gateway.log
        echo "==============="
        echo ""
        kill -9 $GATEWAY_PID 2>/dev/null || true
        rm -f "$PID_FILE"
        exit 1
    fi
    
    # 检查是否就绪
    if grep -q "listening on ws://" /tmp/moltbot-gateway.log 2>/dev/null; then
        READY=1
        echo "✓  Gateway 已就绪 (用时 $((i*2)) 秒)"
        break
    fi
    
    echo "   等待中... ($i/15)"
done

if [ $READY -eq 0 ]; then
    echo ""
    echo "⚠️  Gateway 启动超时，但进程还在运行"
    echo "   查看最新日志："
    echo ""
    tail -n 30 /tmp/moltbot-gateway.log
    echo ""
    echo "可能需要手动检查，或者重新运行脚本"
fi
echo ""

# 6. 验证启动
echo "✅ 验证 Gateway 连接..."
sleep 2
if moltbot channels status --probe 2>/dev/null; then
    echo "✓  Gateway 连接正常"
else
    echo "⚠️  Gateway 连接失败，但进程还在运行"
    echo "   可能需要稍等片刻再试"
    echo "   查看日志: tail -f /tmp/moltbot-gateway.log"
fi

echo ""
echo "📊 当前运行的进程:"
RUNNING_PROCS=$(ps aux | grep -E "[m]oltbot-gateway|[i]msg rpc|[n]ode.*moltbot.*node run" | awk '{print "   PID", $2, $11, $12, $13}')
if [ -n "$RUNNING_PROCS" ]; then
    echo "$RUNNING_PROCS"
else
    echo "   未找到相关进程"
fi

echo ""
echo "📝 日志文件:"
echo "   Gateway: /tmp/moltbot-gateway.log"
echo "   Gateway PID: $PID_FILE"
echo "   Node: /Users/public1/.clawdbot/logs/node.log"
echo "   System: /tmp/moltbot/moltbot-$(date +%Y-%m-%d).log"

echo ""
echo "🎉 启动完成！现在可以从 iPhone 发送测试消息了。"
echo ""
echo "💡 快捷命令:"
echo "   监控日志: tail -f /tmp/moltbot-gateway.log"
echo "   检查状态: moltbot channels status --probe"
echo "   查看进程: cat $PID_FILE"
echo "   停止服务: kill \$(cat $PID_FILE) 或 pkill -9 -f moltbot-gateway"
echo ""

# 显示最后几行日志
echo "📋 最新日志:"
tail -n 5 /tmp/moltbot-gateway.log | sed 's/^/   /'
echo ""
