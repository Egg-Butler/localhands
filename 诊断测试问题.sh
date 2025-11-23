#!/bin/bash

echo "========================================"
echo "OpenHands 测试问题诊断"
echo "========================================"
echo ""

# 1. 检查进程状态
echo "1️⃣ 检查进程状态:"
PYTHON_PID=$(ps aux | grep "run_infer.py" | grep -v grep | awk '{print $2}' | head -1)
if [ -n "$PYTHON_PID" ]; then
    echo "   ✅ Python 进程正在运行 (PID: $PYTHON_PID)"
    ps -p $PYTHON_PID -o etime,command | tail -1
else
    echo "   ❌ Python 进程未运行"
fi
echo ""

# 2. 检查Docker状态
echo "2️⃣ 检查 Docker 状态:"
if docker ps &>/dev/null; then
    echo "   ✅ Docker 服务正常"
    CONTAINER_COUNT=$(docker ps -q | wc -l | tr -d ' ')
    echo "   运行中的容器: $CONTAINER_COUNT"
else
    echo "   ❌ Docker 服务异常"
fi
echo ""

# 3. 检查Docker镜像
echo "3️⃣ 检查 Docker 镜像:"
echo "   OpenHands Runtime 镜像:"
docker images | grep "openhands.*runtime" | head -3 || echo "   未找到"
echo ""
echo "   SWE-Bench 实例镜像:"
docker images | grep "swebench\|django" | head -3 || echo "   未找到 (可能需要下载)"
echo ""

# 4. 检查日志文件
echo "4️⃣ 检查日志文件:"
LATEST_LOG=$(ls -t test_run_7b_*.log 2>/dev/null | head -1)
if [ -n "$LATEST_LOG" ]; then
    echo "   最新日志: $LATEST_LOG"
    LOG_SIZE=$(wc -l < "$LATEST_LOG" 2>/dev/null || echo "0")
    echo "   日志行数: $LOG_SIZE"
    echo ""
    echo "   最后5行:"
    tail -5 "$LATEST_LOG" | sed 's/\x1b\[[0-9;]*m//g'
else
    echo "   ❌ 未找到日志文件"
fi
echo ""

# 5. 检查输出文件
echo "5️⃣ 检查输出文件:"
OUTPUT_JSONL="OpenHands/evaluation/evaluation_outputs/outputs/princeton-nlp__SWE-bench-test/CodeActAgent/qwen2.5-coder_7b_maxiter_25/output.jsonl"
if [ -f "$OUTPUT_JSONL" ]; then
    FILE_SIZE=$(wc -c < "$OUTPUT_JSONL" 2>/dev/null || echo "0")
    LINE_COUNT=$(wc -l < "$OUTPUT_JSONL" 2>/dev/null || echo "0")
    echo "   文件: $OUTPUT_JSONL"
    echo "   大小: $FILE_SIZE 字节"
    echo "   行数: $LINE_COUNT"
    if [ "$LINE_COUNT" -gt 0 ]; then
        echo "   ✅ 有输出数据"
    else
        echo "   ⏳ 文件为空 (测试进行中或卡住)"
    fi
else
    echo "   ⏳ 输出文件尚未创建"
fi
echo ""

# 6. 检查网络连接
echo "6️⃣ 检查网络连接:"
if curl -s --max-time 5 https://ghcr.io > /dev/null 2>&1; then
    echo "   ✅ 可以访问 Docker Hub/GHCR"
else
    echo "   ⚠️  无法访问 Docker Hub/GHCR (可能影响镜像下载)"
fi
echo ""

# 7. 检查Ollama
echo "7️⃣ 检查 Ollama 服务:"
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "   ✅ Ollama 服务正常"
else
    echo "   ❌ Ollama 服务未运行"
fi
echo ""

# 8. 诊断建议
echo "========================================"
echo "💡 诊断建议"
echo "========================================"
echo ""

if [ -n "$PYTHON_PID" ] && [ "$LINE_COUNT" -eq 0 ]; then
    echo "⚠️  进程正在运行但无输出，可能原因:"
    echo ""
    echo "1. Docker 镜像正在下载/构建 (首次运行需要较长时间)"
    echo "   解决方案: 等待 5-10 分钟，或检查网络连接"
    echo ""
    echo "2. 进程卡在某个步骤"
    echo "   解决方案: 查看详细日志: tail -f $LATEST_LOG"
    echo ""
    echo "3. SWE-Bench 实例镜像下载慢"
    echo "   解决方案: 手动拉取镜像或检查代理设置"
    echo ""
    echo "建议操作:"
    echo "  - 等待 5-10 分钟再检查"
    echo "  - 实时查看日志: tail -f $LATEST_LOG"
    echo "  - 检查 Docker 镜像下载: docker images"
fi

echo ""

