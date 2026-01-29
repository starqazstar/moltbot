#!/bin/bash
# Moltbot 诊断脚本 - 检查当前状态

echo "🔍 Moltbot 诊断工具"
echo "=================="
echo ""

# 1. 检查进程
echo "📋 1. 检查运行中的进程:"
echo "---"
GATEWAY_PROCS=$(ps aux | grep -E "[m]oltbot-gateway" || true)
IMSG_PROCS=$(ps aux | grep -E "[i]msg rpc" || true)
NODE_PROCS=$(ps aux | grep -E "[n]ode.*moltbot.*node run" || true)

if [ -n "$GATEWAY_PROCS" ]; then
    echo "✓ Gateway 进程:"
    echo "$GATEWAY_PROCS" | awk '{print "  PID:", $2, "CPU:", $3"%", "MEM:", $4"%", "START:", $9}'
else
    echo "✗ 未找到 Gateway 进程"
fi

if [ -n "$IMSG_PROCS" ]; then
    echo "✓ iMessage 进程:"
    echo "$IMSG_PROCS" | awk '{print "  PID:", $2, "CPU:", $3"%", "MEM:", $4"%"}'
else
    echo "✗ 未找到 iMessage 进程"
fi

if [ -n "$NODE_PROCS" ]; then
    echo "✓ Node service 进程:"
    echo "$NODE_PROCS" | awk '{print "  PID:", $2, "CPU:", $3"%", "MEM:", $4"%"}'
else
    echo "✗ 未找到 Node service 进程"
fi
echo ""

# 2. 检查 PID 文件
echo "📄 2. 检查 PID 文件:"
echo "---"
PID_FILE="/tmp/moltbot-gateway.pid"
if [ -f "$PID_FILE" ]; then
    SAVED_PID=$(cat "$PID_FILE")
    echo "✓ PID 文件存在: $PID_FILE"
    echo "  保存的 PID: $SAVED_PID"
    if ps -p "$SAVED_PID" > /dev/null 2>&1; then
        echo "  ✓ 进程 $SAVED_PID 正在运行"
    else
        echo "  ✗ 进程 $SAVED_PID 未运行（僵尸 PID 文件）"
    fi
else
    echo "✗ 未找到 PID 文件"
fi
echo ""

# 3. 检查端口
echo "🔌 3. 检查端口占用:"
echo "---"
if lsof -i :18789 > /dev/null 2>&1; then
    echo "✓ 端口 18789 被占用:"
    lsof -i :18789 | tail -n +2 | awk '{print "  PID:", $2, "COMMAND:", $1, "USER:", $3}'
else
    echo "✗ 端口 18789 未被占用"
fi
echo ""

# 4. 检查配置
echo "⚙️  4. 检查配置:"
echo "---"
if [ -f "/Users/public1/.clawdbot/moltbot.json" ]; then
    echo "✓ 配置文件存在: /Users/public1/.clawdbot/moltbot.json"
    if [ -n "$CLAWDBOT_GATEWAY_TOKEN" ]; then
        echo "✓ CLAWDBOT_GATEWAY_TOKEN 已设置: ${CLAWDBOT_GATEWAY_TOKEN:0:8}..."
    else
        echo "✗ CLAWDBOT_GATEWAY_TOKEN 未设置"
    fi
else
    echo "✗ 配置文件不存在"
fi
echo ""

# 5. 检查日志
echo "📝 5. 检查日志文件:"
echo "---"
LOG_FILE="/tmp/moltbot-gateway.log"
if [ -f "$LOG_FILE" ]; then
    LOG_SIZE=$(wc -l < "$LOG_FILE")
    LOG_MODIFIED=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$LOG_FILE")
    echo "✓ Gateway 日志存在: $LOG_FILE"
    echo "  行数: $LOG_SIZE"
    echo "  最后修改: $LOG_MODIFIED"
    echo ""
    echo "  最后 10 行:"
    tail -n 10 "$LOG_FILE" | sed 's/^/    /'
    echo ""
    # 检查错误
    ERROR_COUNT=$(grep -c "Error:\|EBADF\|ELIFECYCLE\|failed" "$LOG_FILE" 2>/dev/null || echo "0")
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo "  ⚠️  发现 $ERROR_COUNT 个错误！最近的错误:"
        grep "Error:\|EBADF\|ELIFECYCLE\|failed" "$LOG_FILE" | tail -n 5 | sed 's/^/    /'
    else
        echo "  ✓ 未发现错误"
    fi
else
    echo "✗ 日志文件不存在"
fi
echo ""

# 6. 测试连接
echo "🌐 6. 测试 Gateway 连接:"
echo "---"
if command -v moltbot > /dev/null 2>&1; then
    if timeout 5 moltbot channels status --probe > /dev/null 2>&1; then
        echo "✓ Gateway 连接正常"
        moltbot channels status --probe 2>&1 | grep -E "iMessage|Gateway" | sed 's/^/  /'
    else
        echo "✗ Gateway 连接失败"
    fi
else
    echo "✗ moltbot 命令不存在"
fi
echo ""

# 7. 系统资源
echo "💻 7. 系统资源:"
echo "---"
echo "  负载: $(uptime | awk -F'load average:' '{print $2}')"
echo "  内存: $(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')页 可用"
echo ""

# 8. 建议
echo "💡 8. 建议操作:"
echo "---"
if [ -z "$GATEWAY_PROCS" ]; then
    echo "  → Gateway 未运行，执行: ./start-moltbot.sh"
elif [ "$ERROR_COUNT" -gt 0 ]; then
    echo "  → 发现错误，建议重启: ./stop-moltbot.sh && sleep 3 && ./start-moltbot.sh"
elif ! lsof -i :18789 > /dev/null 2>&1; then
    echo "  → 端口未监听，Gateway 可能启动失败，建议重启"
else
    echo "  ✓ 系统运行正常"
fi
echo ""
echo "=================="
echo "诊断完成"
