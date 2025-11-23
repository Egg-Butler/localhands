#!/bin/bash

# 设置代理
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7890

echo "========================================"
echo "OpenHands 10分钟快速测试 (openhands-lm-7b模型)"
echo "========================================"
echo ""
echo "📋 配置:"
echo "   模型: openhands/openhands-lm-7b"
echo "   实例数: 5 个"
echo "   最大迭代: 25 次"
echo "   预计时间: 8-12 分钟"
echo ""
echo "💡 openhands-lm-7b模型特点:"
echo "   ✅ OpenHands自己训练的模型"
echo "   ✅ 专门针对软件工程任务微调"
echo "   ✅ OpenHands对它有特殊优化处理"
echo "   ⚠️  不支持原生工具调用 (使用mock function calling)"
echo "   ⚠️  使用OpenHands代理服务 (需要网络连接)"
echo "   ✅ 在软件工程任务上可能表现更好"
echo ""

# 工作目录
WORK_DIR="/Users/bitfun/codes/closehands/OpenHands"
cd "$WORK_DIR" || exit 1

# 评测配置 - 使用openhands-lm模型
MODEL_CONFIG="eval_local_model_openhands_lm"
AGENT="CodeActAgent"
EVAL_LIMIT=5
MAX_ITER=25
NUM_WORKERS=1
DATASET="princeton-nlp/SWE-bench_Lite"
DATASET_SPLIT="test"

# 检查网络连接（openhands-lm需要访问OpenHands代理服务）
echo "🔍 检查网络连接..."
if ! curl -s --max-time 5 https://llm-proxy.app.all-hands.dev/health &> /dev/null; then
    echo "⚠️  无法连接到OpenHands代理服务"
    echo "   模型可能需要网络访问，请确保网络连接正常"
    echo "   继续运行测试..."
else
    echo "✅ 网络连接正常"
fi
echo ""

# 创建输出目录
OUTPUT_DIR="$WORK_DIR/evaluation/evaluation_outputs/quick_openhands_lm_10min_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

# 设置环境变量
export WORKSPACE_BASE="$WORK_DIR/workspace"
export CACHE_DIR="$WORK_DIR/cache"
export EVAL_OUTPUT_DIR="$OUTPUT_DIR"
export EVAL_NOTE="quick-openhands-lm-10min-test"

# 记录开始时间
START_TIME=$(date +%s)
echo "⏱️  开始时间: $(date '+%H:%M:%S')"
echo ""
echo "🚀 开始快速测试 (使用openhands-lm-7b模型)..."
echo ""

# 运行评测
poetry run python evaluation/benchmarks/swe_bench/run_infer.py \
    --llm-config "$MODEL_CONFIG" \
    --agent-cls "$AGENT" \
    --max-iterations "$MAX_ITER" \
    --eval-num-workers "$NUM_WORKERS" \
    --eval-n-limit "$EVAL_LIMIT" \
    --data-split "$DATASET_SPLIT" \
    --dataset-name "$DATASET"

# 检查结果
if [ $? -eq 0 ]; then
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))
    
    echo ""
    echo "========================================"
    echo "✅ 快速测试完成!"
    echo "========================================"
    echo "⏱️  实际用时: ${MINUTES}分${SECONDS}秒"
    echo "📁 结果目录: $OUTPUT_DIR"
    echo ""
    
    # 查找输出文件
    OUTPUT_JSONL=$(find "$WORK_DIR/evaluation/evaluation_outputs" -name "output.jsonl" -path "*openhands_lm*" | head -1)
    
    if [ -n "$OUTPUT_JSONL" ]; then
        echo "📊 输出文件: $OUTPUT_JSONL"
        echo ""
        echo "📈 快速统计:"
        TOTAL=$(wc -l < "$OUTPUT_JSONL" 2>/dev/null || echo "0")
        echo "   完成实例: $TOTAL 个"
        echo ""
        echo "💡 下一步:"
        echo "   1. 查看结果: head -1 $OUTPUT_JSONL | python3 -m json.tool | head -50"
        echo "   2. 对比其他模型结果"
    fi
else
    echo ""
    echo "❌ 测试失败,请检查错误信息"
    exit 1
fi

echo ""

