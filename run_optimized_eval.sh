#!/bin/bash

# 设置代理
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7890

echo "================================"
echo "OpenHands 优化评测脚本"
echo "================================"
echo ""

# 工作目录
WORK_DIR="/Users/bitfun/codes/closehands/OpenHands"
cd "$WORK_DIR" || exit 1

# 评测配置 - 优化版本
MODEL_CONFIG="eval_local_model_optimized"
AGENT="CodeActAgent"
EVAL_LIMIT=50  # 与基线相同数量
MAX_ITER=100   # 🔧 优化1: 增加迭代次数
NUM_WORKERS=1
DATASET="princeton-nlp/SWE-bench_Lite"
DATASET_SPLIT="test"

echo "📋 优化评测配置:"
echo "   模型配置: $MODEL_CONFIG (使用更大模型)"
echo "   Agent: $AGENT"
echo "   评测实例数: $EVAL_LIMIT"
echo "   最大迭代: $MAX_ITER (优化: 50 → 100)"
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

# 检查是否有 32B 模型
echo "🔍 检查优化模型 (qwen2.5-coder:32b)..."
if ! ollama list | grep -q "qwen2.5-coder:32b"; then
    echo "⚠️  优化模型 (32B) 未安装"
    echo "   选项 1: 使用 14B 模型进行优化评测 (仅测试其他优化策略)"
    echo "   选项 2: 下载 32B 模型 (约需 10-30 分钟)"
    read -p "   选择 (1/2): " choice
    
    if [ "$choice" == "2" ]; then
        echo "📥 正在下载 qwen2.5-coder:32b..."
        ollama pull qwen2.5-coder:32b
        if [ $? -ne 0 ]; then
            echo "❌ 模型下载失败"
            exit 1
        fi
    else
        echo "📝 将使用 14B 模型运行优化评测 (仅策略优化)"
        MODEL_CONFIG="eval_local_model"  # 回退到 14B
    fi
fi

echo "✅ 模型准备就绪"
echo ""

# 创建输出目录
OUTPUT_DIR="$WORK_DIR/evaluation/evaluation_outputs/optimized_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"
echo "📁 输出目录: $OUTPUT_DIR"
echo ""

# 设置环境变量 - 启用优化策略
export WORKSPACE_BASE="$WORK_DIR/workspace"
export CACHE_DIR="$WORK_DIR/cache"
export EVAL_OUTPUT_DIR="$OUTPUT_DIR"
export EVAL_NOTE="optimized-qwen2.5-coder-32b-enhanced"

# 🔧 优化策略环境变量
export ITERATIVE_EVAL_MODE=true  # 🔧 优化2: 启用迭代评测模式
export EVAL_CONDENSER="optimized_condenser"  # 🔧 优化3: 使用优化的上下文管理

# 记录开始时间
START_TIME=$(date +%s)
echo "⏱️  开始时间: $(date)"
echo ""

echo "🎯 启用的优化策略:"
echo "   ✅ 策略1: 使用更大模型 (14B → 32B)"
echo "   ✅ 策略2: 增加迭代次数 (50 → 100)"
echo "   ✅ 策略3: 启用迭代评测模式"
echo "   ✅ 策略4: 优化上下文管理 (LLM Attention)"
echo "   ✅ 策略5: 启用自动 Linting (config.toml)"
echo ""

# 运行评测
echo "🚀 开始优化评测..."
echo "   这可能需要更长时间 (每个实例约 5-15 分钟)"
echo "   总预计时间: $(($EVAL_LIMIT * 7 / 60)) - $(($EVAL_LIMIT * 15 / 60)) 小时"
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
    echo "✅ 优化评测完成!"
    echo "================================"
    echo "⏱️  用时: ${HOURS}小时${MINUTES}分钟"
    echo "📁 结果保存在: $OUTPUT_DIR"
    echo ""
    
    # 查找输出文件
    OUTPUT_JSONL=$(find "$WORK_DIR/evaluation/evaluation_outputs" -name "output.jsonl" -type f | grep -i "optimized\|qwen.*32b" | head -1)
    
    if [ -n "$OUTPUT_JSONL" ]; then
        echo "📊 输出文件: $OUTPUT_JSONL"
        echo ""
        echo "📌 下一步:"
        echo "   1. 查看初步结果: head -5 $OUTPUT_JSONL"
        echo "   2. 运行评估: ./evaluation/benchmarks/swe_bench/scripts/eval_infer.sh $OUTPUT_JSONL"
        echo "   3. 对比分析: python compare_results.py"
    else
        echo "⚠️  输出文件未找到，请检查评测日志"
    fi
else
    echo ""
    echo "❌ 优化评测失败，请检查错误信息"
    exit 1
fi

echo ""

