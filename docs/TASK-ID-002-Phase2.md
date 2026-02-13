# 阶段二：知识库 Schema 设计

## 设计原则
1. **贴合考试导向**: 字段围绕「考点」而非「笔记」
2. **高度结构化**: 便于 AI 提取和出题
3. **极简主义**: 拒绝信息收集癖

---

## 方案 A：Notion Database Schema (推荐)

### 数据库结构

| 字段名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| **Name** | Title | 知识点名称 | "temperature 参数的行为边界" |
| **Tags** | Multi-select | 分类标签 | #ACL #LLM #Prompt |
| **黑话翻译** | Text | 自然语言 → 标准术语 | "更像人话" → "RLHF/Constitutional AI" |
| **考点参数** | Text/JSON | 核心参数及值 | `temperature: 0.7 (0=确定,1=随机)` |
| **边界条件** | Text | 失效场景 | "timeout>60s 时 API 会返回 504" |
| **来源场景** | Select | 萃取的原始场景 | "Cursor 功能开发" |
| **考试频次** | Select | ⭐ 到 ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **掌握程度** | Select | 待掌握/已熟悉/已遗忘 | 待掌握 |
| **复习周期** | Date | 下次复习日期 | 2026-02-20 |
| **Created** | Date | 创建时间 | 自动 |

### 筛选视图建议

```markdown
## 视图 1: 「待复习」
- 筛选: 掌握程度 = "待掌握"
- 排序: 复习周期 Asc

## 视图 2: 「高频考点」
- 筛选: 考试频次 >= ⭐⭐⭐
- 排序: 考试频次 Desc

## 视图 3: 「按标签」
- 分组: Tags
```

### 标签体系建议

```
# 云计算
  # ACP # 阿里云 # AWS # 容器 # K8s # Serverless

# 大模型
  # LLM # RAG # Prompt # RLHF # Token

# 编程
  # Python # Rust # VibeCoding # Cursor

# 架构
  # 微服务 # 分布式 # 高可用
```

---

## 方案 B：SQLite/JSON 文件 (极简方案)

### Schema 设计

```sql
-- 知识点表
CREATE TABLE knowledge (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,           -- 知识点名称
    raw_expression TEXT,           -- 我的原始表达
    standard_term TEXT,            -- 标准黑话
    source_scenario TEXT,          -- 来源场景
    core_params TEXT,              -- 核心参数 (JSON)
    boundary_conditions TEXT,      -- 边界条件 (JSON)
    tags TEXT,                     -- 标签 (JSON数组)
    exam_frequency INTEGER,         -- 1-5 考试频次
    mastery_level INTEGER,          -- 1-5 掌握程度
    review_date DATE,              -- 下次复习日期
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME
);

-- 复习记录表
CREATE TABLE review_log (
    id INTEGER PRIMARY KEY,
    knowledge_id INTEGER,
    review_date DATETIME,
    result TEXT,                   -- pass/fail/forgot
    notes TEXT,
    FOREIGN KEY (knowledge_id) REFERENCES knowledge(id)
);
```

### 示例数据

```json
{
  "id": 1,
  "title": "temperature 参数的行为边界",
  "raw_expression": "让 AI 回答更像人话",
  "standard_term": "RLHF / Constitutional AI / 温度系数",
  "source_scenario": "Cursor 功能开发 - OpenAI API 调用",
  "core_params": {
    "temperature": {
      "value": "0.7",
      "range": "0.0 - 2.0",
      "meaning": "0=确定性输出, 1=标准随机, 2=高度随机"
    }
  },
  "boundary_conditions": [
    "temperature=0 时可能陷入重复循环",
    "temperature=2 时可能产生无意义输出"
  ],
  "tags": ["LLM", "Prompt", "OpenAI"],
  "exam_frequency": 4,
  "mastery_level": 2,
  "review_date": "2026-02-20"
}
```

---

## 方案 C：Obsidian Dataview (极客方案)

### Frontmatter Schema

```yaml
---
tags:
  - #LLM
  - #RAG
raw_expression: "让 AI 回答更像人话"
standard_term: "RLHF / Constitutional AI"
source_scenario: "Cursor - OpenAI API"
core_params:
  temperature: "0.7 (0=确定, 1=随机)"
boundary_conditions:
  - "temperature=0 可能重复"
exam_frequency: 4
mastery_level: 2
review_date: 2026-02-20
created: 2026-02-13
---

# temperature 参数的行为边界

## 黑话翻译
- 我的表达：「让 AI 回答更像人话」
- 标准黑话：RLHF / Constitutional AI

## 核心参数
- `temperature: 0.7`
- 范围：0.0 - 2.0
- 含义：...

## 边界条件
1. ...
2. ...
```

---

## 推荐方案

| 方案 | 适合人群 | 推荐指数 |
|------|----------|----------|
| A. Notion | 跨设备、可视化强 | ⭐⭐⭐⭐⭐ |
| B. SQLite | 纯本地、隐私性强 | ⭐⭐⭐⭐ |
| C. Obsidian | 极客、本地写作 | ⭐⭐⭐⭐ |

**推荐选择 A (Notion)**，原因：
- 天然支持多设备同步
- 数据库视图强大，适合备考筛选
- 可直接作为「阶段三」的传输目标

---

## 快速开始 (Notion 版)

1. 新建 Notion Database
2. 创建上述字段
3. 设置筛选视图
4. 获取 Integration Token
5. 配置「阶段三」自动化管道

---

*此 Schema 由逆向知识印钞机系统 v1.0 设计*
