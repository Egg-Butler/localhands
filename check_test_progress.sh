#!/bin/bash

echo "========================================"
echo "检查测试运行进度"
echo "========================================"
echo ""

# 查找最新的日志文件
LATEST_LOG=$(ls -t test_run_7b_*.log 2>/dev/null | head -1)

if [ -z "$LATEST_LOG" ]; then
    echo "❌ 未找到运行日志文件"
    echo ""
    echo "可能的原因:"
    echo "  1. 测试还未开始"
    echo "  2. 日志文件在其他位置"
    exit 1
fi

echo "📋 日志文件: $LATEST_LOG"
echo ""

# 显示最后20行
echo "--- 最新日志 (最后20行) ---"
tail -20 "$LATEST_LOG" 2>/dev/null || echo "日志文件为空或无法读取"
echo ""

# 检查是否有输出文件
OUTPUT_DIR=$(find OpenHands/evaluation/evaluation_outputs -type d -name "*quick_7b*" 2>/dev/null | sort -r | head -1)

if [ -n "$OUTPUT_DIR" ]; then
    echo "📁 输出目录: $OUTPUT_DIR"
    
    OUTPUT_JSONL="$OUTPUT_DIR/output.jsonl"
    if [ -f "$OUTPUT_JSONL" ]; then
        COMPLETED=$(wc -l < "$OUTPUT_JSONL" 2>/dev/null || echo "0")
        echo "✅ 已完成实例数: $COMPLETED"
        echo ""
        echo "--- 最新完成的实例 ---"
        tail -1 "$OUTPUT_JSONL" | python3 -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    print(f\"实例ID: {data.get('instance_id', 'unknown')}\")
    print(f\"是否有patch: {'git_patch' in data and bool(data.get('git_patch'))}\")
    if 'metrics' in data:
        print(f\"Token数: {data['metrics'].get('total_tokens', 'N/A')}\")
except:
    print('解析中...')
" 2>/dev/null || echo "解析中..."
    else
        echo "⏳ 输出文件尚未生成 (测试进行中...)"
    fi
else
    echo "⏳ 输出目录尚未创建 (测试初始化中...)"
fi

echo ""
echo "💡 提示: 运行 'tail -f $LATEST_LOG' 可以实时查看日志"

