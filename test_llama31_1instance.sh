#!/bin/bash

# 设置代理
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7890

echo "========================================"
echo "OpenHands 单实例测试 (Llama-3.1-8B)"
echo "========================================"
echo ""

WORK_DIR="/Users/bitfun/codes/closehands/OpenHands"
cd "$WORK_DIR" || exit 1

# 评测配置
MODEL_CONFIG="eval_local_model_llama3"
AGENT="CodeActAgent"
MAX_ITER=25
NUM_WORKERS=1
EVAL_LIMIT=1
DATASET="princeton-nlp/SWE-bench_Lite"
DATASET_SPLIT="test"

# 检查 Ollama 服务
echo "🔍 检查 Ollama 服务..."
if ! curl -s http://localhost:11434/api/tags &> /dev/null; then
    echo "❌ Ollama 服务未运行"
    exit 1
fi
echo "✅ Ollama 服务正常"
echo ""

# 检查模型
echo "🔍 检查 Llama3.1 模型..."
if ! ollama list | grep -q "llama3.1"; then
    echo "❌ Llama3.1 模型未安装"
    exit 1
fi
echo "✅ Llama3.1 模型准备就绪"
echo ""

# 创建日志文件
LOG_FILE="../test_llama31_1instance_$(date +%Y%m%d_%H%M%S).log"
echo "📝 日志文件: $LOG_FILE"
echo ""

# 设置环境变量
export WORKSPACE_BASE="$WORK_DIR/workspace"
export CACHE_DIR="$WORK_DIR/cache"

# 运行评测
echo "🚀 开始测试 (1个实例)..." | tee -a "$LOG_FILE"
echo ""

poetry run python evaluation/benchmarks/swe_bench/run_infer.py \
    --llm-config "$MODEL_CONFIG" \
    --agent-cls "$AGENT" \
    --max-iterations "$MAX_ITER" \
    --eval-num-workers "$NUM_WORKERS" \
    --eval-n-limit "$EVAL_LIMIT" \
    --data-split "$DATASET_SPLIT" \
    --dataset-name "$DATASET" 2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=$?
echo ""
echo "========================================"
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ 测试完成!"
else
    echo "⚠️  测试中断或失败 (退出码: $EXIT_CODE)"
fi
echo "========================================"
echo "📁 日志文件: $LOG_FILE"
echo ""

