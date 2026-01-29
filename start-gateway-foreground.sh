#!/bin/bash

# 前台启动 Moltbot Gateway（实时查看日志）

set -e

echo "🚀 启动 Moltbot Gateway (前台模式)..."
echo "按 Ctrl+C 停止"
echo ""

cd ~/ai-clawdbot/clawdbot

# 停止现有进程
pkill -9 -f moltbot-gateway 2>/dev/null || true
sleep 1

# 前台启动（不使用 nohup）
exec pnpm moltbot gateway run --bind loopback --port 18789 --force
