#!/bin/bash
# OpenHands 10分钟快速测试 (gpt-oss-20b模型)

set -e

# 设置代理
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7890

echo "========================================"
echo "OpenHands 10分钟快速测试 (gpt-oss-20b模型)"
echo "========================================"
echo ""
echo "配置信息:"
echo "  模型: gpt-oss-20b (OpenAI 开源模型)"
echo "  参数: 21B (MoE, 每个token激活约3.6B)"
echo "  上下文: 128K tokens"
echo "  部署: Ollama"
echo ""

cd "$(dirname "$0")/OpenHands" || exit 1

# 检查 Ollama 服务
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "❌ Ollama 服务未运行"
    echo "   请先启动 Ollama: ollama serve"
    exit 1
fi

# 检查模型是否已下载
if ! ollama list | grep -q "gpt-oss:20b"; then
    echo "⚠️  模型 gpt-oss:20b 未找到"
    echo "   正在检查下载状态..."
    echo "   如果正在下载，请等待下载完成后再运行此脚本"
    echo ""
    read -p "是否现在开始下载? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "开始下载 gpt-oss:20b (约 13GB)..."
        ollama pull gpt-oss:20b
    else
        echo "已取消。请先下载模型: ollama pull gpt-oss:20b"
        exit 1
    fi
fi

echo "✅ 模型已就绪"
echo ""

# 测试配置
MODEL_CONFIG="eval_local_model_gpt_oss_20b"
AGENT="CodeActAgent"
EVAL_LIMIT=5
MAX_ITER=25
NUM_WORKERS=1
DATASET_SPLIT="test"
DATASET="princeton-nlp/SWE-bench_Lite"

echo "测试参数:"
echo "  模型配置: $MODEL_CONFIG"
echo "  Agent: $AGENT"
echo "  测试实例数: $EVAL_LIMIT"
echo "  最大迭代次数: $MAX_ITER"
echo "  数据集: $DATASET"
echo ""

# 创建输出目录
OUTPUT_DIR="evaluation/evaluation_outputs/outputs/${DATASET//\//__}/$AGENT/gpt_oss_20b_maxiter_$MAX_ITER"
mkdir -p "$OUTPUT_DIR"

echo "开始测试..."
echo "预计时间: 8-12 分钟"
echo ""

START_TIME=$(date +%s)

# 运行评测
poetry run python evaluation/benchmarks/swe_bench/run_infer.py \
    --llm-config "$MODEL_CONFIG" \
    --agent-cls "$AGENT" \
    --max-iterations "$MAX_ITER" \
    --eval-num-workers "$NUM_WORKERS" \
    --eval-n-limit "$EVAL_LIMIT" \
    --data-split "$DATASET_SPLIT" \
    --dataset-name "$DATASET" \
    2>&1 | tee "../test_gpt_oss_20b_$(date +%Y%m%d_%H%M%S).log"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo "========================================"
echo "测试完成!"
echo "========================================"
echo "总耗时: ${MINUTES}分${SECONDS}秒"
echo ""

# 分析结果
OUTPUT_FILE="$OUTPUT_DIR/output.jsonl"
if [ -f "$OUTPUT_FILE" ]; then
    echo "结果分析:"
    python3 << 'PYEOF'
import json
import sys

output_file = sys.argv[1]
try:
    with open(output_file, 'r') as f:
        results = [json.loads(line) for line in f]
    
    total = len(results)
    with_patch = sum(1 for r in results if r.get('test_result', {}).get('git_patch', '').strip())
    without_patch = total - with_patch
    
    print(f"  总实例数: {total}")
    print(f"  生成patch: {with_patch} ({with_patch*100//total if total > 0 else 0}%)")
    print(f"  未生成patch: {without_patch} ({without_patch*100//total if total > 0 else 0}%)")
    
    if without_patch > 0:
        print("\n  未生成patch的实例:")
        for r in results:
            if not r.get('test_result', {}).get('git_patch', '').strip():
                error = r.get('error', 'Unknown error')
                print(f"    - {r.get('instance_id', 'unknown')}: {error[:100]}")
except Exception as e:
    print(f"  解析结果时出错: {e}")
PYEOF
    "$OUTPUT_FILE"
else
    echo "⚠️  结果文件未找到: $OUTPUT_FILE"
fi

echo ""
echo "结果文件: $OUTPUT_FILE"
echo "日志文件: test_gpt_oss_20b_*.log"
echo ""

