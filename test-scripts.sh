#!/bin/bash
# 快速测试所有管理脚本

echo "🧪 测试 Moltbot 管理脚本"
echo "======================="
echo ""

cd "$(dirname "$0")"

# 测试 1: 检查文件是否存在
echo "📋 1. 检查文件..."
FILES=("start-moltbot.sh" "stop-moltbot.sh" "diagnose-moltbot.sh")
ALL_EXISTS=1

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        if [ -x "$file" ]; then
            echo "  ✓ $file (可执行)"
        else
            echo "  ⚠️  $file (存在但不可执行)"
            chmod +x "$file"
            echo "     → 已添加执行权限"
        fi
    else
        echo "  ✗ $file (不存在)"
        ALL_EXISTS=0
    fi
done
echo ""

# 测试 2: 语法检查
echo "📋 2. 语法检查..."
SYNTAX_OK=1

for file in "${FILES[@]}"; do
    if bash -n "$file" 2>/dev/null; then
        echo "  ✓ $file 语法正确"
    else
        echo "  ✗ $file 语法错误"
        bash -n "$file"
        SYNTAX_OK=0
    fi
done
echo ""

# 测试 3: 运行诊断脚本
echo "📋 3. 运行诊断..."
echo "---"
if [ -x "diagnose-moltbot.sh" ]; then
    ./diagnose-moltbot.sh
else
    echo "  ✗ 诊断脚本不可用"
fi
echo ""

# 总结
echo "======================="
echo "测试总结:"
if [ $ALL_EXISTS -eq 1 ] && [ $SYNTAX_OK -eq 1 ]; then
    echo "✅ 所有脚本正常"
    echo ""
    echo "💡 使用说明:"
    echo "   启动: ./start-moltbot.sh"
    echo "   停止: ./stop-moltbot.sh"
    echo "   诊断: ./diagnose-moltbot.sh"
else
    echo "❌ 发现问题，请检查上述输出"
fi
echo ""
