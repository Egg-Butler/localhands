#!/bin/bash

# 设置代理
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7890

echo "========================================"
echo "OpenHands 10分钟快速测试 (Llama-3.1-8B模型)"
echo "========================================"
echo ""
echo "📋 配置:"
echo "   模型: llama3.1:8b-instruct-q4_0"
echo "   实例数: 5 个"
echo "   最大迭代: 25 次"
echo "   预计时间: 8-12 分钟"
echo ""
echo "💡 Llama-3.1-8B模型特点:"
echo "   ✅ 更好的指令理解能力"
echo "   ✅ 经过指令微调"
echo "   ⚠️  不支持原生工具调用 (使用mock function calling)"
echo "   ⚠️  可能比qwen2.5-coder在工具调用格式上表现更好"
echo ""

# 工作目录
WORK_DIR="/Users/bitfun/codes/closehands/OpenHands"
cd "$WORK_DIR" || exit 1

# 评测配置 - 使用Llama-3.1模型
MODEL_CONFIG="eval_local_model_llama3"
AGENT="CodeActAgent"
EVAL_LIMIT=5
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

# 检查Llama-3.1模型
echo "🔍 检查 Llama-3.1 模型..."
if ! ollama list | grep -q "llama3.1:8b-instruct-q4_0"; then
    echo "❌ Llama-3.1 模型未安装"
    echo "   正在下载 llama3.1:8b-instruct-q4_0 (约 4.7GB)..."
    ollama pull llama3.1:8b-instruct-q4_0
    if [ $? -ne 0 ]; then
        echo "❌ 模型下载失败"
        echo "   尝试其他名称: llama3.1:8b"
        ollama pull llama3.1:8b
        if [ $? -ne 0 ]; then
            echo "❌ 模型下载失败，请检查网络连接"
            exit 1
        fi
        # 更新配置使用备用模型名称
        sed -i '' 's/llama3.1:8b-instruct-q4_0/llama3.1:8b/g' config.toml
    fi
fi
echo "✅ Llama-3.1 模型准备就绪"
echo ""

# 创建输出目录
OUTPUT_DIR="$WORK_DIR/evaluation/evaluation_outputs/quick_llama3_10min_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

# 设置环境变量
export WORKSPACE_BASE="$WORK_DIR/workspace"
export CACHE_DIR="$WORK_DIR/cache"
export EVAL_OUTPUT_DIR="$OUTPUT_DIR"
export EVAL_NOTE="quick-llama3-10min-test"

# 记录开始时间
START_TIME=$(date +%s)
echo "⏱️  开始时间: $(date '+%H:%M:%S')"
echo ""
echo "🚀 开始快速测试 (使用Llama-3.1模型)..."
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
    OUTPUT_JSONL=$(find "$WORK_DIR/evaluation/evaluation_outputs" -name "output.jsonl" -path "*llama3*" | head -1)
    
    if [ -n "$OUTPUT_JSONL" ]; then
        echo "📊 输出文件: $OUTPUT_JSONL"
        echo ""
        echo "📈 快速统计:"
        TOTAL=$(wc -l < "$OUTPUT_JSONL" 2>/dev/null || echo "0")
        echo "   完成实例: $TOTAL 个"
        echo ""
        echo "💡 下一步:"
        echo "   1. 查看结果: head -1 $OUTPUT_JSONL | python3 -m json.tool | head -50"
        echo "   2. 对比7B和14B模型结果"
    fi
else
    echo ""
    echo "❌ 测试失败,请检查错误信息"
    exit 1
fi

echo ""

