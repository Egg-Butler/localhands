#!/bin/bash

# 设置代理
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7890

echo "================================"
echo "OpenHands 基线评测脚本"
echo "================================"
echo ""

# 工作目录
WORK_DIR="/Users/bitfun/codes/closehands/OpenHands"
cd "$WORK_DIR" || exit 1

# 评测配置
MODEL_CONFIG="eval_local_model"
AGENT="CodeActAgent"
EVAL_LIMIT=50  # 先测试 50 个实例
MAX_ITER=50
NUM_WORKERS=1
DATASET="princeton-nlp/SWE-bench_Lite"
DATASET_SPLIT="test"

echo "📋 评测配置:"
echo "   模型配置: $MODEL_CONFIG"
echo "   Agent: $AGENT"
echo "   评测实例数: $EVAL_LIMIT"
echo "   最大迭代: $MAX_ITER"
echo "   并发数: $NUM_WORKERS"
echo "   数据集: $DATASET"
echo ""

# 检查 Ollama 服务
echo "🔍 检查 Ollama 服务状态..."
if ! curl -s http://localhost:11434/api/tags &> /dev/null; then
    echo "❌ Ollama 服务未运行，请先运行: ollama serve"
    exit 1
fi
echo "✅ Ollama 服务正常"
echo ""

# 创建输出目录
OUTPUT_DIR="$WORK_DIR/evaluation/evaluation_outputs/baseline_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"
echo "📁 输出目录: $OUTPUT_DIR"
echo ""

# 设置环境变量
export WORKSPACE_BASE="$WORK_DIR/workspace"
export CACHE_DIR="$WORK_DIR/cache"
export EVAL_OUTPUT_DIR="$OUTPUT_DIR"
export EVAL_NOTE="baseline-qwen2.5-coder-14b"

# 记录开始时间
START_TIME=$(date +%s)
echo "⏱️  开始时间: $(date)"
echo ""

# 运行评测
echo "🚀 开始基线评测..."
echo "   这可能需要较长时间 (每个实例约 3-10 分钟)"
echo "   总预计时间: $(($EVAL_LIMIT * 5 / 60)) - $(($EVAL_LIMIT * 10 / 60)) 小时"
echo ""

poetry run python evaluation/benchmarks/swe_bench/run_infer.py \
    --llm-config "$MODEL_CONFIG" \
    --agent-cls "$AGENT" \
    --max-iterations "$MAX_ITER" \
    --eval-num-workers "$NUM_WORKERS" \
    --eval-n-limit "$EVAL_LIMIT" \
    --data-split "$DATASET_SPLIT" \
    --dataset-name "$DATASET"

# 检查运行结果
if [ $? -eq 0 ]; then
    # 记录结束时间
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    HOURS=$((DURATION / 3600))
    MINUTES=$(((DURATION % 3600) / 60))
    
    echo ""
    echo "================================"
    echo "✅ 基线评测完成!"
    echo "================================"
    echo "⏱️  用时: ${HOURS}小时${MINUTES}分钟"
    echo "📁 结果保存在: $OUTPUT_DIR"
    echo ""
    
    # 查找输出文件
    OUTPUT_JSONL=$(find "$WORK_DIR/evaluation/evaluation_outputs" -name "output.jsonl" -type f | grep -i "baseline\|qwen.*14b" | head -1)
    
    if [ -n "$OUTPUT_JSONL" ]; then
        echo "📊 输出文件: $OUTPUT_JSONL"
        echo ""
        echo "📌 下一步:"
        echo "   1. 查看初步结果: head -5 $OUTPUT_JSONL"
        echo "   2. 运行评估: ./evaluation/benchmarks/swe_bench/scripts/eval_infer.sh $OUTPUT_JSONL"
        echo "   3. 运行优化评测: ./run_optimized_eval.sh"
    else
        echo "⚠️  输出文件未找到，请检查评测日志"
    fi
else
    echo ""
    echo "❌ 基线评测失败，请检查错误信息"
    exit 1
fi

echo ""

