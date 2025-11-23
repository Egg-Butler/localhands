#!/bin/bash

# 设置代理
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7890

echo "========================================"
echo "OpenHands 测试 (Devstral-Small-2505 本地部署)"
echo "========================================"
echo ""
echo "📋 配置:"
echo "   模型: ollama/devstral (本地部署)"
echo "   实例数: 2 个"
echo "   最大迭代: 25 次"
echo "   预计时间: 15-20分钟"
echo ""
echo "💡 Devstral-Small-2505 特点:"
echo "   ✅ 24B参数，轻量级"
echo "   ✅ SWE-Bench准确率: 46.8% (开源模型第一)"
echo "   ✅ 128K上下文窗口"
echo "   ✅ 专门针对软件工程任务优化"
echo "   ⚠️  不支持原生工具调用 (使用mock function calling)"
echo "   ✅ OpenHands对它有特殊优化处理"
echo ""

# 工作目录
WORK_DIR="/Users/bitfun/codes/closehands/OpenHands"
cd "$WORK_DIR" || exit 1

# 评测配置 - 使用Devstral本地模型
MODEL_CONFIG="eval_local_model_devstral"
AGENT="CodeActAgent"
EVAL_LIMIT=2
MAX_ITER=25
NUM_WORKERS=1
DATASET="princeton-nlp/SWE-bench_Lite"
DATASET_SPLIT="test"

# 检查 Ollama 服务
echo "🔍 检查 Ollama 服务..."
if ! curl -s http://localhost:11434/api/tags &> /dev/null; then
    echo "❌ Ollama 服务未运行"
    echo "   请运行: ollama serve"
    exit 1
fi
echo "✅ Ollama 服务正常"
echo ""

# 检查Devstral模型
echo "🔍 检查 Devstral 模型..."
if ! ollama list | grep -q "devstral"; then
    echo "❌ Devstral 模型未安装"
    echo "   正在下载 devstral (约 14GB)..."
    ollama pull devstral
    if [ $? -ne 0 ]; then
        echo "❌ 模型下载失败，请检查网络连接"
        exit 1
    fi
fi
echo "✅ Devstral 模型准备就绪"
echo ""

# 创建输出目录
OUTPUT_DIR="$WORK_DIR/evaluation/evaluation_outputs/quick_devstral_local_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

# 设置环境变量
export WORKSPACE_BASE="$WORK_DIR/workspace"
export CACHE_DIR="$WORK_DIR/cache"
export EVAL_OUTPUT_DIR="$OUTPUT_DIR"
export EVAL_NOTE="quick-devstral-local-test"

# 记录开始时间
START_TIME=$(date +%s)
echo "⏱️  开始时间: $(date '+%H:%M:%S')"
echo ""
echo "🚀 开始测试 (使用Devstral-Small-2505本地模型)..."
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
    echo "✅ 测试完成!"
    echo "========================================"
    echo "⏱️  实际用时: ${MINUTES}分${SECONDS}秒"
    echo "📁 结果目录: $OUTPUT_DIR"
    echo ""
    
    # 查找输出文件
    OUTPUT_JSONL=$(find "$WORK_DIR/evaluation/evaluation_outputs" -name "output.jsonl" -path "*devstral*" | head -1)
    
    if [ -n "$OUTPUT_JSONL" ]; then
        echo "📊 输出文件: $OUTPUT_JSONL"
        echo ""
        echo "📈 快速统计:"
        TOTAL=$(wc -l < "$OUTPUT_JSONL" 2>/dev/null || echo "0")
        PATCH_COUNT=$(grep -c '"git_patch":"[^"]*[^"]"' "$OUTPUT_JSONL" 2>/dev/null || echo "0")
        echo "   完成实例: $TOTAL 个"
        echo "   生成patch: $PATCH_COUNT 个"
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

