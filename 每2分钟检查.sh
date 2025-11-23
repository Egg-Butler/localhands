#!/bin/bash

# 每2分钟检查一次下载/构建进度

echo "========================================"
echo "🔍 每2分钟检查 Docker 下载/构建进度"
echo "========================================"
echo ""

CHECK_COUNT=0
MAX_CHECKS=15  # 最多检查15次 (30分钟)

while [ $CHECK_COUNT -lt $MAX_CHECKS ]; do
    CHECK_COUNT=$((CHECK_COUNT + 1))
    CURRENT_TIME=$(date '+%H:%M:%S')
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "检查 #$CHECK_COUNT - $CURRENT_TIME"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # 1. 检查进程
    PYTHON_PID=$(ps aux | grep "run_infer.py" | grep -v grep | awk '{print $2}' | head -1)
    if [ -n "$PYTHON_PID" ]; then
        ETIME=$(ps -p $PYTHON_PID -o etime= 2>/dev/null | tr -d ' ')
        echo "✅ Python 进程: 运行中 (PID: $PYTHON_PID, 运行时间: $ETIME)"
    else
        echo "❌ Python 进程: 已结束"
        echo ""
        echo "测试可能已完成或失败"
        break
    fi
    echo ""
    
    # 2. 检查 Docker 镜像 (检查是否有新镜像或镜像大小变化)
    echo "📦 Docker 镜像:"
    
    # OpenHands Runtime 镜像
    OPENHANDS_IMGS=$(docker images --format "{{.Repository}}:{{.Tag}}\t{{.Size}}" | grep "openhands.*runtime" | head -3)
    if [ -n "$OPENHANDS_IMGS" ]; then
        echo "   ✅ OpenHands Runtime 镜像:"
        echo "$OPENHANDS_IMGS" | sed 's/^/      /'
    else
        echo "   ⏳ OpenHands Runtime: 尚未构建完成"
    fi
    
    # SWE-Bench 实例镜像
    SWEBENCH_IMGS=$(docker images --format "{{.Repository}}:{{.Tag}}\t{{.Size}}" | grep -E "swebench|django.*13230" | head -3)
    if [ -n "$SWEBENCH_IMGS" ]; then
        echo "   ✅ SWE-Bench 实例镜像:"
        echo "$SWEBENCH_IMGS" | sed 's/^/      /'
    else
        echo "   ⏳ SWE-Bench 实例镜像: 尚未下载"
    fi
    echo ""
    
    # 3. 检查 Docker 容器
    CONTAINER_COUNT=$(docker ps -q | wc -l | tr -d ' ')
    if [ "$CONTAINER_COUNT" -gt 0 ]; then
        echo "🐳 运行中的容器: $CONTAINER_COUNT"
        docker ps --format "   - {{.Names}} ({{.Status}})" | head -3
    else
        echo "🐳 运行中的容器: 0 (可能在构建镜像)"
    fi
    echo ""
    
    # 4. 检查输出文件
    OUTPUT_FILE="OpenHands/evaluation/evaluation_outputs/outputs/princeton-nlp__SWE-bench-test/CodeActAgent/qwen2.5-coder_7b_maxiter_25/output.jsonl"
    if [ -f "$OUTPUT_FILE" ]; then
        FILE_SIZE=$(wc -c < "$OUTPUT_FILE" 2>/dev/null || echo "0")
        LINE_COUNT=$(wc -l < "$OUTPUT_FILE" 2>/dev/null || echo "0")
        if [ "$LINE_COUNT" -gt 0 ]; then
            echo "✅ 输出文件: $LINE_COUNT / 5 个实例已完成"
            if [ "$LINE_COUNT" -ge 5 ]; then
                echo ""
                echo "🎉 所有实例已完成!"
                break
            fi
        else
            echo "⏳ 输出文件: 存在但为空"
        fi
    else
        echo "⏳ 输出文件: 尚未创建"
    fi
    echo ""
    
    # 5. 检查最新日志
    LATEST_LOG=$(ls -t test_run_7b_*.log 2>/dev/null | head -1)
    if [ -n "$LATEST_LOG" ]; then
        LOG_LINES=$(wc -l < "$LATEST_LOG" 2>/dev/null || echo "0")
        echo "📋 日志文件: $LATEST_LOG ($LOG_LINES 行)"
        echo "   最新3行:"
        tail -3 "$LATEST_LOG" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^/      /'
    fi
    echo ""
    
    # 如果不是最后一次检查,等待2分钟
    if [ $CHECK_COUNT -lt $MAX_CHECKS ]; then
        echo "⏳ 等待 2 分钟后再次检查..."
        echo ""
        sleep 120  # 等待2分钟
    fi
done

echo ""
echo "========================================"
echo "监控结束"
echo "========================================"

