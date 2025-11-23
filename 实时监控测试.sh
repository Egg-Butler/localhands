#!/bin/bash

echo "========================================"
echo "OpenHands 测试实时监控"
echo "========================================"
echo ""

# 查找最新的日志文件
LATEST_LOG=$(ls -t test_run_7b_*.log 2>/dev/null | head -1)

if [ -z "$LATEST_LOG" ]; then
    echo "❌ 未找到运行日志"
    exit 1
fi

echo "📋 日志文件: $LATEST_LOG"
echo "⏱️  当前时间: $(date '+%H:%M:%S')"
echo ""

# 检查Docker容器
echo "🐳 Docker 容器状态:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | grep -E "NAME|openhands|swebench" | head -5
echo ""

# 显示最新日志
echo "--- 最新日志 (最后15行) ---"
tail -15 "$LATEST_LOG" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g'  # 移除ANSI颜色代码
echo ""

# 检查输出文件
OUTPUT_JSONL="OpenHands/evaluation/evaluation_outputs/outputs/princeton-nlp__SWE-bench-test/CodeActAgent/qwen2.5-coder_7b_maxiter_25/output.jsonl"

if [ -f "$OUTPUT_JSONL" ]; then
    COMPLETED=$(wc -l < "$OUTPUT_JSONL" 2>/dev/null || echo "0")
    echo "✅ 已完成实例数: $COMPLETED / 5"
    
    if [ "$COMPLETED" -gt 0 ]; then
        echo ""
        echo "--- 最新完成的实例 ---"
        tail -1 "$OUTPUT_JSONL" | python3 -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    print(f\"  实例ID: {data.get('instance_id', 'unknown')}\")
    has_patch = 'git_patch' in data and bool(data.get('git_patch', '').strip())
    print(f\"  生成patch: {'✅ 是' if has_patch else '❌ 否'}\")
    if 'metrics' in data:
        tokens = data['metrics'].get('total_tokens', 0)
        print(f\"  使用Token: {tokens:,}\")
    if 'error' in data and data['error']:
        print(f\"  错误: {data['error'][:100]}...\")
except Exception as e:
    print(f\"  解析中... ({e})\")
" 2>/dev/null
    fi
else
    echo "⏳ 输出文件尚未生成"
    echo "   可能正在:"
    echo "   - 构建 Docker 镜像 (首次运行需要几分钟)"
    echo "   - 下载 SWE-Bench 实例镜像"
    echo "   - 初始化运行环境"
fi

echo ""
echo "💡 实时查看: tail -f $LATEST_LOG"
echo "💡 再次检查: ./实时监控测试.sh"

