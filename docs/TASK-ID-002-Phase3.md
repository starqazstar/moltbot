# 阶段三：macOS 自动化管道

## 设计原则
1. **一键触发**: 不超过 2 步操作
2. **跨设备同步**: Mac mini ↔ MacBook Pro
3. **低阻力**: 0 学习成本，10 秒内完成

---

## 方案一：Raycast 脚本 + 快捷指令 (推荐)

### 架构图

```
Cursor (.cursorrules 萃取)
    ↓ 复制到剪贴板
Raycast 快捷命令 (⌘+Shift+K)
    ↓ 解析格式
Apple Shortcuts (iCloud 同步)
    ↓
Notion Database (知识库)
```

### Step 1: 创建 Raycast 脚本

```bash
#!/bin/bash
# File: ~/Library/Application Support/Raycast/scripts/KnowledgePush.sh

# 从剪贴板获取萃取的知识点
CONTENT=$(pbpaste)

# 检查是否为空
if [ -z "$CONTENT" ]; then
  echo "❌ 剪贴板为空，请先复制知识点"
  exit 1
fi

# 提取标题 (第一行)
TITLE=$(echo "$CONTENT" | head -1 | sed 's/^# //')

# 发送到 Shortcuts
osascript <<EOF
tell application "Shortcuts"
    run shortcut "知识萃取推送" with input "$CONTENT"
end tell
EOF

echo "✅ 已推送: $TITLE"
```

### Step 2: 创建 Apple Shortcuts 快捷指令

**快捷指令名称**: 「知识萃取推送」

**输入**: 剪贴板内容

**步骤**:

```
1. Get Clipboard                    ← 获取萃取的知识点
2. Split Text (分隔符: "### ")      ← 解析结构
3. Get Item from List (第1项)       ← 标题
4. Get Item from List (第2项)       ← 黑话翻译
5. Get Item from List (第3项)       ← 考点参数
6. Get Item from List (第4项)       ← 边界条件
7. Get Item from List (第5项)       ← 标签
8. Notion Create Database Item      ← 推送到 Notion
   - Database: 逆向知识印钞机
   - Name: [标题]
   - Tags: [标签]
   - 黑话翻译: [第2项]
   - 核心参数: [第3项]
   - 边界条件: [第4项]
9. Show Notification               ← 完成提示
```

### Step 3: 配置 Notion Integration

```bash
# 1. 创建 Notion Integration
# https://www.notion.so/my-integrations

# 2. 获取 Internal Integration Token
NOTION_TOKEN="secret_xxxxx"

# 3. 获取 Database ID
# Database URL 中间那一串: https://notion.so/myworkspace/xxxxx

# 4. 分享 Database 给 Integration
```

### Step 4: Raycast 快捷键绑定

1. 打开 Raycast → Settings → Extensions
2. 添加脚本目录: `~/Library/Application Support/Raycast/scripts`
3. 绑定快捷键: `⌘ + Shift + K`
4. 测试: 在 Cursor 萃取后 → `⌘+C` → `⌘+Shift+K`

---

## 方案二：Make.com (无代码方案)

### 架构

```
Cursor (复制)
    ↓ (Webhook)
Make.com Scenario
    ↓ (Notion API)
Notion Database
```

### Make.com Scenario 配置

**Trigger**: Webhook
```
URL: https://hook.make.com/xxxxx
```

**Module 1**: Webhook (接收数据)
```json
{
  "title": "...",
  "tags": "...",
  "params": "...",
  "boundary": "...",
  "raw_expression": "..."
}
```

**Module 2**: Notion (创建条目)
```
Database: 逆向知识印钞机
Title: {{title}}
Tags: {{tags}}
黑话翻译: {{raw_expression}} → {{standard_term}}
核心参数: {{params}}
边界条件: {{boundary}}
```

**Module 3**: Slack/通知 (可选)
```
发送到指定频道提醒
```

### 触发方式

**Option A**: Shortcuts 调用 Make
- 快捷指令: 「推送到知识库」
- Action: Run Make.com Scenario

**Option B**: Raycast 调用 Shortcuts
- 同方案一

---

## 方案三：纯本地 (Obsidian + Git)

### 架构

```
Cursor (复制)
    ↓
Obsidian QuickAdd
    ↓ (Git sync)
GitHub / iCloud
    ↓
双 Mac 同步
```

### Obsidian QuickAdd 配置

```javascript
// QuickAdd 脚本: KnowledgeCapture.js

module.exports = {
    name: '知识萃取',
    actions: [
        {
            type: 'Prompt',
            prompt: '请粘贴萃取的知识点',
            handler: async (input, canvas, ...args) => {
                // 解析格式
                const lines = input.split('\n');
                const title = lines[0].replace('# ', '');
                const content = lines.slice(1).join('\n');
                
                // 生成 Frontmatter
                const frontmatter = `---
tags: []
exam_frequency: 3
mastery_level: 1
review_date: ${new Date().toISOString().split('T')[0]}
created: ${new Date().toISOString()}
---

# ${title}

${content}
`;
                // 保存到文件
                const filename = `knowledge/${Date.now()}.md`;
                await app.vault.create(filename, frontmatter);
                
                return `✅ 已保存: ${filename}`;
            }
        }
    ]
}
```

### Git 同步

```bash
# 在 Obsidian 仓库中
cd ~/Documents/Obsidian/Knowledge
git add .
git commit -m "知识萃取: $(date +%Y-%m-%d %H:%M)"
git push origin main
```

---

## 三方案对比

| 维度 | 方案一 (Raycast+Shortcuts) | 方案二 (Make) | 方案三 (Obsidian) |
|------|----------------------------|---------------|-------------------|
| **学习成本** | ⭐⭐ (1小时) | ⭐⭐⭐ (2小时) | ⭐⭐⭐⭐ (3小时) |
| **同步速度** | ⭐⭐⭐⭐⭐ (秒级) | ⭐⭐⭐ (分钟级) | ⭐⭐⭐⭐⭐ (秒级) |
| **跨设备** | ✅ iCloud | ✅ 云端 | ✅ Git/iCloud |
| **隐私** | ⭐⭐⭐⭐ | ⭐⭐⭐ (数据过云) | ⭐⭐⭐⭐⭐ (本地) |
| **可视化** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **推荐场景** | Notion 用户 | 无代码偏好 | 极客/本地优先 |

---

## 推荐配置

**如果用 Notion**: 方案一 (Raycast + Shortcuts)
**如果怕折腾**: 方案二 (Make.com)
**如果本地优先**: 方案三 (Obsidian + Git)

---

## 一键触发流程 (方案一示例)

```
1. Cursor 完成开发 → 说「完成了」
2. Cursor 自动输出萃取报告
3. ⌘+A 全选 → ⌘+C 复制
4. ⌘+Shift+K (Raycast)
5. ✅ "已推送: temperature 参数的行为边界"
6. Notion 自动新增条目
```

---

## 故障排查

| 问题 | 原因 | 解决 |
|------|------|------|
| Shortcuts 找不到 Notion | Integration 没分享 Database | 在 Notion 中分享 Database |
| 剪贴板为空 | pbpaste 权限问题 | System Settings → Privacy → Clipboard |
| Raycast 脚本不执行 | 权限问题 | chmod +x script.sh |

---

*此方案由逆向知识印钞机系统 v1.0 设计*
