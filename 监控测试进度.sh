#!/bin/bash

# 实时监控测试进度

LATEST_LOG=$(ls -t test_run_7b_*.log 2>/dev/null | head -1)

if [ -z "$LATEST_LOG" ]; then
    echo "❌ 未找到日志文件"
    exit 1
fi

echo "========================================"
echo "📊 测试运行状态监控"
echo "========================================"
echo ""
echo "日志文件: $LATEST_LOG"
echo ""

# 检查进程
PYTHON_PID=$(ps aux | grep "run_infer.py" | grep -v grep | awk '{print $2}' | head -1)
if [ -n "$PYTHON_PID" ]; then
    ETIME=$(ps -p $PYTHON_PID -o etime= 2>/dev/null | tr -d ' ')
    echo "✅ Python 进程: 运行中 (PID: $PYTHON_PID, 运行时间: $ETIME)"
else
    echo "❌ Python 进程: 已结束"
fi
echo ""

# 检查输出文件
OUTPUT_FILE="OpenHands/evaluation/evaluation_outputs/outputs/princeton-nlp__SWE-bench-test/CodeActAgent/qwen2.5-coder_7b_maxiter_25/output.jsonl"
if [ -f "$OUTPUT_FILE" ]; then
    LINE_COUNT=$(wc -l < "$OUTPUT_FILE" 2>/dev/null || echo "0")
    FILE_SIZE=$(wc -c < "$OUTPUT_FILE" 2>/dev/null || echo "0")
    echo "📁 输出文件: $LINE_COUNT / 5 个实例已完成 ($FILE_SIZE 字节)"
else
    echo "📁 输出文件: 尚未创建"
fi
echo ""

# 检查最新日志中的关键信息
echo "📋 最新日志 (最后20行):"
echo "----------------------------------------"
tail -20 "$LATEST_LOG" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g'
echo ""

# 检查是否有错误
ERROR_COUNT=$(grep -i "error\|failed\|exception" "$LATEST_LOG" 2>/dev/null | wc -l | tr -d ' ')
if [ "$ERROR_COUNT" -gt 0 ]; then
    echo "⚠️  发现 $ERROR_COUNT 个错误/警告"
    echo ""
    echo "最近的错误:"
    grep -i "error\|failed\|exception" "$LATEST_LOG" 2>/dev/null | tail -3
fi

