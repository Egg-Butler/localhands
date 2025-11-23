#!/bin/bash

echo "=========================================="
echo "诊断卡住的optimized测评进程"
echo "=========================================="
echo ""

# 查找optimized测评进程
PROCESS_ID=$(ps aux | grep "run_infer.py.*optimized" | grep -v grep | awk '{print $2}' | head -1)

if [ -z "$PROCESS_ID" ]; then
    echo "❌ 未找到optimized测评进程"
    exit 1
fi

echo "📋 进程ID: $PROCESS_ID"
echo ""

# 检查进程状态
echo "🔍 进程状态:"
ps -p $PROCESS_ID -o pid,pcpu,pmem,etime,state,command
echo ""

# 检查进程运行时间
START_TIME=$(ps -p $PROCESS_ID -o lstart= | awk '{print $4}')
CURRENT_TIME=$(date +%H:%M:%S)
echo "⏰ 进程启动时间: $START_TIME"
echo "⏰ 当前时间: $CURRENT_TIME"
echo ""

# 检查vLLM服务
echo "🔍 检查vLLM服务状态:"
if curl -s -m 5 http://192.168.50.114:8000/v1/models > /dev/null 2>&1; then
    echo "✅ vLLM服务正常"
else
    echo "❌ vLLM服务无法访问"
fi
echo ""

# 检查Docker容器
echo "🔍 检查Docker容器:"
docker ps --filter "name=openhands-runtime" --format "table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}" | head -5
echo ""

# 检查日志最后更新时间
LOG_FILE="/Users/bitfun/codes/closehands/docker_image_mappings/optimized/logs/evaluation_20251124_043452.log"
if [ -f "$LOG_FILE" ]; then
    LAST_LOG_TIME=$(tail -1 "$LOG_FILE" | grep -oP '\d{2}:\d{2}:\d{2}' | head -1)
    echo "📝 日志最后更新时间: $LAST_LOG_TIME"
    echo ""
fi

# 检查是否有输出文件
OUTPUT_DIR="/Users/bitfun/codes/closehands/OpenHands/evaluation/evaluation_outputs/outputs/princeton-nlp__SWE-bench_Lite-test/CodeActAgent/Qwen3-14B-AWQ_maxiter_25_N_optimized"
if [ -f "$OUTPUT_DIR/output.jsonl" ]; then
    LINE_COUNT=$(wc -l < "$OUTPUT_DIR/output.jsonl")
    echo "📊 已完成的实例数: $LINE_COUNT"
    echo ""
fi

echo "=========================================="
echo "建议操作:"
echo "=========================================="
echo "1. 如果进程卡住超过30分钟，可以尝试:"
echo "   kill -USR1 $PROCESS_ID  # 发送信号查看堆栈"
echo ""
echo "2. 如果确认卡住，可以终止进程:"
echo "   kill $PROCESS_ID"
echo ""
echo "3. 检查vLLM服务是否有请求队列:"
echo "   curl http://192.168.50.114:8000/v1/models"
echo ""
echo "4. 查看Docker容器日志:"
echo "   docker logs openhands-runtime-3d5a31be-cdaf-4c-355a51bea854dca"
echo ""

