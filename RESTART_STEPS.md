# Moltbot 重启后操作步骤

## 🔄 重启 Mac 后需要做的事情

### 1️⃣ 启动 Gateway
```bash
cd /Users/public1/ai-clawdbot/clawdbot
export CLAWDBOT_GATEWAY_TOKEN="local-dev-token"
nohup pnpm moltbot gateway run --bind loopback --port 18789 --force > ~/.clawdbot/logs/gateway.log 2>&1 &
```

### 2️⃣ 等待 3 秒后检查状态
```bash
sleep 3
moltbot channels status
```

### 3️⃣ 启动 Mac 应用
```bash
open /Users/public1/ai-clawdbot/clawdbot/dist/Moltbot.app
```

### 4️⃣ 验证 iMessage 权限是否生效
```bash
moltbot channels status
```

期望看到：
```
Gateway reachable. ✅
- iMessage default: enabled, configured, running ✅
```

如果仍然有权限错误，检查：
```bash
tail -50 ~/.clawdbot/logs/gateway.log | grep -i "imessage\|permission"
```

---

## 📝 配置摘要

- **Gateway Token**: `local-dev-token`
- **Gateway Port**: 18789
- **AI Model**: OpenAI Codex / GPT-5.2
- **Workspace**: ~/clawd
- **iMessage**: 已启用（需要完全磁盘访问权限）

---

## 🆘 如果遇到问题

### Gateway 无法连接
```bash
# 检查进程
ps aux | grep moltbot

# 重启 gateway
pkill -f "moltbot.*gateway"
export CLAWDBOT_GATEWAY_TOKEN="local-dev-token"
nohup pnpm moltbot gateway run --bind loopback --port 18789 --force > ~/.clawdbot/logs/gateway.log 2>&1 &
```

### Mac 应用显示 token 错误
检查配置文件中的 token 是否为 `local-dev-token`：
```bash
cat ~/.clawdbot/moltbot.json | grep -A 2 "auth"
```

---

## ✅ 成功标志

当一切正常时，你应该能：
1. 从 iPhone 给 Mac 发 iMessage
2. Mac 通过 Moltbot 自动回复（使用 OpenAI GPT-5.2）
3. 在 Mac 菜单栏看到 Moltbot 图标

---

祝一切顺利！🎉
