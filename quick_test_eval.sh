#!/bin/bash

# 设置代理
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7890

echo "================================"
echo "OpenHands 快速测试评测"
echo "================================"
echo ""
echo "⚠️  这是一个快速测试脚本,仅评测 3 个实例"
echo "   用于验证环境配置是否正确"
echo ""

# 工作目录
WORK_DIR="/Users/bitfun/codes/closehands/OpenHands"
cd "$WORK_DIR" || exit 1

# 评测配置 - 最小化测试
MODEL_CONFIG="eval_local_model"
AGENT="CodeActAgent"
EVAL_LIMIT=3  # 只测试 3 个实例
MAX_ITER=20   # 减少迭代次数以加快测试
NUM_WORKERS=1
DATASET="princeton-nlp/SWE-bench_Lite"
DATASET_SPLIT="test"

echo "📋 测试配置:"
echo "   模型: qwen2.5-coder:14b"
echo "   评测实例数: $EVAL_LIMIT (快速测试)"
echo "   最大迭代: $MAX_ITER"
echo ""

# 检查 Ollama 服务
echo "🔍 检查 Ollama 服务..."
if ! curl -s http://localhost:11434/api/tags &> /dev/null; then
    echo "❌ Ollama 服务未运行"
    echo ""
    echo "请执行以下步骤:"
    echo "1. 打开新终端窗口"
    echo "2. 运行: ollama serve"
    echo "3. 返回此窗口并重新运行此脚本"
    exit 1
fi
echo "✅ Ollama 服务正常"
echo ""

# 检查模型
echo "🔍 检查模型..."
if ! ollama list | grep -q "qwen2.5-coder:14b"; then
    echo "❌ 模型未安装,正在下载..."
    ollama pull qwen2.5-coder:14b
    if [ $? -ne 0 ]; then
        echo "❌ 模型下载失败"
        exit 1
    fi
fi
echo "✅ 模型准备就绪"
echo ""

# 测试模型连接
echo "🧪 测试模型响应..."
TEST_RESPONSE=$(curl -s -X POST http://localhost:11434/api/generate \
    -d '{"model": "qwen2.5-coder:14b", "prompt": "Hello", "stream": false}' \
    | python3 -c "import sys, json; print(json.load(sys.stdin).get('response', 'error'))" 2>&1)

if [ $? -eq 0 ] && [ "$TEST_RESPONSE" != "error" ]; then
    echo "✅ 模型响应正常"
else
    echo "❌ 模型响应异常,请检查 Ollama 服务"
    exit 1
fi
echo ""

# 创建输出目录
OUTPUT_DIR="$WORK_DIR/evaluation/evaluation_outputs/quick_test_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

# 设置环境变量
export WORKSPACE_BASE="$WORK_DIR/workspace"
export CACHE_DIR="$WORK_DIR/cache"
export EVAL_OUTPUT_DIR="$OUTPUT_DIR"
export EVAL_NOTE="quick-test"

echo "🚀 开始快速测试评测..."
echo "   预计时间: 5-15 分钟"
echo ""

# 记录开始时间
START_TIME=$(date +%s)

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
    echo "================================"
    echo "✅ 快速测试完成!"
    echo "================================"
    echo "⏱️  用时: ${MINUTES}分${SECONDS}秒"
    echo ""
    
    # 查找输出文件
    OUTPUT_JSONL=$(find "$WORK_DIR/evaluation/evaluation_outputs" -name "output.jsonl" -type f -path "*quick_test*" | head -1)
    
    if [ -n "$OUTPUT_JSONL" ]; then
        echo "📊 输出文件: $OUTPUT_JSONL"
        echo ""
        echo "📝 查看结果:"
        echo "   基本信息: head -3 $OUTPUT_JSONL | jq '.instance_id, .test_result.resolved'"
        echo ""
        echo "✅ 环境配置正常!可以运行完整评测:"
        echo "   基线评测: ./run_baseline_eval.sh"
        echo "   优化评测: ./run_optimized_eval.sh"
    else
        echo "⚠️  输出文件未找到"
        echo "   请检查: $WORK_DIR/evaluation/evaluation_outputs/"
    fi
else
    echo ""
    echo "❌ 测试失败"
    echo ""
    echo "常见问题排查:"
    echo "1. Ollama 服务是否正在运行? (ollama serve)"
    echo "2. 模型是否已下载? (ollama list)"
    echo "3. 网络代理是否配置? (echo \$https_proxy)"
    echo "4. Python 依赖是否安装? (poetry install --with evaluation)"
    exit 1
fi

echo ""

