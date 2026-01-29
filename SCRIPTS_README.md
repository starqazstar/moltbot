# Moltbot 管理脚本

这是一套用于管理 Moltbot Gateway 的脚本工具集。

## 📋 脚本说明

### 1. `start-moltbot.sh` - 启动脚本
完整的 Moltbot Gateway 启动脚本，包含：
- ✅ 自动设置环境变量（`CLAWDBOT_GATEWAY_TOKEN`）
- ✅ 优雅停止旧进程
- ✅ 清理端口占用
- ✅ 等待 Gateway 就绪（最多 30 秒）
- ✅ 错误检测和自动诊断
- ✅ 详细的状态反馈

### 2. `stop-moltbot.sh` - 停止脚本
安全停止 Moltbot Gateway，包含：
- ✅ 优雅关闭（SIGTERM + 等待）
- ✅ 强制终止（SIGKILL）
- ✅ 清理残留进程
- ✅ 释放端口占用
- ✅ 删除 PID 文件

### 3. `diagnose-moltbot.sh` - 诊断脚本
全面的系统诊断工具，检查：
- ✅ 运行中的进程
- ✅ PID 文件状态
- ✅ 端口占用情况
- ✅ 配置文件和环境变量
- ✅ 日志文件和错误
- ✅ Gateway 连接测试
- ✅ 系统资源
- ✅ 提供修复建议

## 🚀 使用方法

### 启动 Moltbot
```bash
./start-moltbot.sh
```

### 停止 Moltbot
```bash
./stop-moltbot.sh
```

### 诊断问题
```bash
./diagnose-moltbot.sh
```

### 完全重启
```bash
./stop-moltbot.sh && sleep 3 && ./start-moltbot.sh
```

## 📝 日志位置

- **Gateway 日志**: `/tmp/moltbot-gateway.log`
- **PID 文件**: `/tmp/moltbot-gateway.pid`
- **Node 日志**: `/Users/public1/.clawdbot/logs/node.log`
- **系统日志**: `/tmp/moltbot/moltbot-YYYY-MM-DD.log`

## 🔍 快捷命令

```bash
# 实时监控日志
tail -f /tmp/moltbot-gateway.log

# 检查状态
moltbot channels status --probe

# 查看进程
ps aux | grep -E '[m]oltbot|[i]msg'

# 检查端口
lsof -i :18789

# 查看 PID
cat /tmp/moltbot-gateway.pid

# 手动停止
kill $(cat /tmp/moltbot-gateway.pid)
```

## ⚠️ 常见问题

### 1. Gateway 启动失败（EBADF 错误）
**原因**: 文件描述符未释放，通常是旧进程没有完全清理

**解决**:
```bash
./stop-moltbot.sh
sleep 5
./start-moltbot.sh
```

### 2. 端口被占用
**原因**: 端口 18789 被其他进程占用

**解决**:
```bash
# 查看占用进程
lsof -i :18789

# 清理端口
lsof -ti :18789 | xargs kill -9
```

### 3. Gateway 无法连接
**原因**: Gateway 进程启动了但没有监听

**解决**:
```bash
# 先诊断
./diagnose-moltbot.sh

# 查看完整日志
cat /tmp/moltbot-gateway.log

# 重启
./stop-moltbot.sh && sleep 5 && ./start-moltbot.sh
```

### 4. Node service 未运行
**原因**: iMessage Node service 没有启动

**解决**:
```bash
# 检查状态
moltbot node status

# 手动启动
launchctl bootstrap gui/$UID ~/Library/LaunchAgents/bot.molt.node.plist
```

## 🛠️ 环境变量

### CLAWDBOT_GATEWAY_TOKEN
Gateway 认证令牌，启动脚本会自动设置默认值 `local-dev-token`

如需自定义：
```bash
export CLAWDBOT_GATEWAY_TOKEN="your-custom-token"
./start-moltbot.sh
```

## 📊 脚本工作流程

### start-moltbot.sh 流程
1. 设置工作目录和环境变量
2. 停止所有现有进程（优雅关闭 → 强制终止）
3. 检查并启动 Node service
4. 清理端口占用
5. 启动 Gateway
6. 等待就绪（检测日志中的 "listening on ws://"）
7. 错误检测（EBADF、ELIFECYCLE 等）
8. 验证连接
9. 显示状态和日志

### stop-moltbot.sh 流程
1. 读取 PID 文件
2. 发送 SIGTERM 信号
3. 等待 10 秒优雅关闭
4. 如仍在运行，发送 SIGKILL
5. 清理残留进程（moltbot-gateway、imsg rpc）
6. 释放端口占用
7. 删除 PID 文件

### diagnose-moltbot.sh 流程
1. 检查所有相关进程
2. 验证 PID 文件
3. 检查端口占用
4. 检查配置和环境变量
5. 分析日志文件（大小、错误）
6. 测试 Gateway 连接
7. 显示系统资源
8. 提供修复建议

## 📦 文件清单

```
.
├── start-moltbot.sh      # 启动脚本
├── stop-moltbot.sh       # 停止脚本
├── diagnose-moltbot.sh   # 诊断脚本
└── SCRIPTS_README.md     # 本文档
```

## 🎯 最佳实践

1. **启动前先诊断**: `./diagnose-moltbot.sh` 可以快速发现问题
2. **完全重启**: 如果遇到问题，完全停止后等待 3-5 秒再启动
3. **监控日志**: 使用 `tail -f` 实时监控启动过程
4. **保留日志**: 出问题时保存 `/tmp/moltbot-gateway.log` 用于分析

## 📞 支持

如果脚本无法解决问题，请：
1. 运行 `./diagnose-moltbot.sh` 并保存输出
2. 保存 `/tmp/moltbot-gateway.log` 日志文件
3. 提供错误信息和重现步骤
