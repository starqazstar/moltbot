# Moltbot 配置备份

这是我的 Moltbot 个人配置备份仓库。

## ⚠️ 安全提示

- 本仓库**不包含**任何敏感信息（API keys、tokens、认证凭证）
- 所有敏感文件已通过 `.gitignore` 排除
- 不要将 `auth-profiles.json` 或 `credentials/` 目录提交到 git

## 📁 包含的配置

- `moltbot.json` - 主配置文件（不含敏感信息）
- `start-gateway.sh` - Gateway 启动脚本
- `RESTART_STEPS.md` - 重启步骤文档

## 🔧 恢复配置

1. 克隆本仓库到 `~/.clawdbot/`
2. 手动配置认证信息：
   ```bash
   # 使用 Moltbot CLI 重新登录
   moltbot models auth login --provider anthropic
   moltbot models auth login --provider openai-codex
   ```
3. 启动 Gateway

## 📝 配置说明

### 模型配置
- 主模型：`anthropic/claude-sonnet-4-5`
- 认证方式：OAuth token

### iMessage 配置
- 策略：`allowlist`
- 允许的号码：已配置（见 `moltbot.json`）

### 代理配置
- 使用 TUN 模式 VPN
- 代理地址：`127.0.0.1:7890`

## 🔄 最后更新

更新日期：2026-01-29
Moltbot 版本：2026.1.27-beta.1
