#!/bin/bash

# 每2分钟检查一次下载进度

echo "========================================"
echo "🔍 Docker 镜像下载/构建监控"
echo "========================================"
echo ""

CHECK_COUNT=0
MAX_CHECKS=30  # 最多检查30次 (60分钟)

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
        echo "测试可能已完成或失败,请检查日志"
        break
    fi
    echo ""
    
    # 2. 检查 Docker 镜像
    echo "📦 Docker 镜像状态:"
    OPENHANDS_IMG=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "openhands.*runtime" | head -1)
    if [ -n "$OPENHANDS_IMG" ]; then
        IMG_SIZE=$(docker images --format "{{.Repository}}:{{.Tag}}\t{{.Size}}" | grep "openhands.*runtime" | head -1 | awk '{print $2}')
        echo "   ✅ OpenHands Runtime: $OPENHANDS_IMG ($IMG_SIZE)"
    else
        echo "   ⏳ OpenHands Runtime: 正在构建/下载..."
    fi
    
    SWEBENCH_IMG=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "swebench|django.*13230" | head -1)
    if [ -n "$SWEBENCH_IMG" ]; then
        IMG_SIZE=$(docker images --format "{{.Repository}}:{{.Tag}}\t{{.Size}}" | grep -E "swebench|django.*13230" | head -1 | awk '{print $2}')
        echo "   ✅ SWE-Bench 实例镜像: $SWEBENCH_IMG ($IMG_SIZE)"
    else
        echo "   ⏳ SWE-Bench 实例镜像: 正在下载..."
    fi
    echo ""
    
    # 3. 检查 Docker 容器
    echo "🐳 Docker 容器:"
    CONTAINER_COUNT=$(docker ps -q | wc -l | tr -d ' ')
    if [ "$CONTAINER_COUNT" -gt 0 ]; then
        echo "   ✅ 运行中的容器: $CONTAINER_COUNT"
        docker ps --format "   - {{.Names}} ({{.Status}})" | head -3
    else
        echo "   ⏳ 暂无运行中的容器 (可能在构建镜像)"
    fi
    echo ""
    
    # 4. 检查输出文件
    OUTPUT_FILE="OpenHands/evaluation/evaluation_outputs/outputs/princeton-nlp__SWE-bench-test/CodeActAgent/qwen2.5-coder_7b_maxiter_25/output.jsonl"
    if [ -f "$OUTPUT_FILE" ]; then
        FILE_SIZE=$(wc -c < "$OUTPUT_FILE" 2>/dev/null || echo "0")
        LINE_COUNT=$(wc -l < "$OUTPUT_FILE" 2>/dev/null || echo "0")
        if [ "$LINE_COUNT" -gt 0 ]; then
            echo "✅ 输出文件: $LINE_COUNT / 5 个实例已完成"
            echo ""
            echo "   最新完成的实例:"
            tail -1 "$OUTPUT_FILE" | python3 -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    print(f\"   - {data.get('instance_id', 'unknown')}\")
    has_patch = 'git_patch' in data and bool(data.get('git_patch', '').strip())
    print(f\"   - 生成patch: {'✅' if has_patch else '❌'}\")
except:
    print('   - 解析中...')
" 2>/dev/null
            echo ""
            if [ "$LINE_COUNT" -ge 5 ]; then
                echo "🎉 所有实例已完成!"
                break
            fi
        else
            echo "⏳ 输出文件: 存在但为空 (等待中...)"
        fi
    else
        echo "⏳ 输出文件: 尚未创建"
    fi
    echo ""
    
    # 5. 检查最新日志
    LATEST_LOG=$(ls -t test_run_7b_*.log 2>/dev/null | head -1)
    if [ -n "$LATEST_LOG" ]; then
        echo "📋 最新日志 (最后3行):"
        tail -3 "$LATEST_LOG" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^/   /'
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

