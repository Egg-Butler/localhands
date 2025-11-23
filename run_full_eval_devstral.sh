#!/bin/bash

# 设置代理
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7890

echo "========================================"
echo "OpenHands 完整评测集测试 (Devstral-Small-2505)"
echo "========================================"
echo ""
echo "📋 配置:"
echo "   模型: ollama/devstral (本地部署)"
echo "   评测集: 完整 SWE-bench_Lite 测试集"
echo "   最大迭代: 25 次"
echo "   预计时间: 数小时（取决于实例数量和模型速度）"
echo ""
echo "💡 Devstral-Small-2505 特点:"
echo "   ✅ 24B参数，SWE-Bench准确率: 46.8% (开源模型第一)"
echo "   ✅ 128K上下文窗口"
echo "   ✅ 专门针对软件工程任务优化"
echo "   ⚠️  在Mac上推理速度较慢，请耐心等待"
echo ""
echo "📝 日志说明:"
echo "   - 完整日志将保存到: test_devstral_full_eval_YYYYMMDD_HHMMSS.log"
echo "   - 结果文件: OpenHands/evaluation/evaluation_outputs/outputs/.../output.jsonl"
echo "   - 可以随时按 Ctrl+C 停止，已完成的实例会保存"
echo ""

# 工作目录
WORK_DIR="/Users/bitfun/codes/closehands/OpenHands"
cd "$WORK_DIR" || exit 1

# 评测配置 - 使用Devstral本地模型，完整评测集
MODEL_CONFIG="eval_local_model_devstral"
AGENT="CodeActAgent"
MAX_ITER=25
NUM_WORKERS=1
# 不设置 eval-n-limit，运行完整评测集
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
    echo "   请先运行: ollama pull devstral"
    exit 1
fi
echo "✅ Devstral 模型准备就绪"
echo ""

# 创建日志文件
LOG_FILE="../test_devstral_full_eval_$(date +%Y%m%d_%H%M%S).log"
echo "📝 日志文件: $LOG_FILE"
echo ""

# 设置环境变量
export WORKSPACE_BASE="$WORK_DIR/workspace"
export CACHE_DIR="$WORK_DIR/cache"
export EVAL_NOTE="full-eval-devstral-$(date +%Y%m%d)"

# 记录开始时间
START_TIME=$(date +%s)
echo "⏱️  开始时间: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "🚀 开始完整评测集测试 (使用Devstral-Small-2505本地模型)..." | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# 运行评测 - 不设置 eval-n-limit，运行完整评测集
# 使用 tee 同时输出到终端和日志文件
poetry run python evaluation/benchmarks/swe_bench/run_infer.py \
    --llm-config "$MODEL_CONFIG" \
    --agent-cls "$AGENT" \
    --max-iterations "$MAX_ITER" \
    --eval-num-workers "$NUM_WORKERS" \
    --data-split "$DATASET_SPLIT" \
    --dataset-name "$DATASET" 2>&1 | tee -a "$LOG_FILE"

# 检查结果
EXIT_CODE=$?
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
HOURS=$((DURATION / 3600))
MINUTES=$(((DURATION % 3600) / 60))
SECONDS=$((DURATION % 60))

echo "" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ 测试完成!" | tee -a "$LOG_FILE"
else
    echo "⚠️  测试中断或失败 (退出码: $EXIT_CODE)" | tee -a "$LOG_FILE"
fi
echo "========================================" | tee -a "$LOG_FILE"
echo "⏱️  总用时: ${HOURS}小时${MINUTES}分${SECONDS}秒" | tee -a "$LOG_FILE"
echo "📁 日志文件: $LOG_FILE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# 查找输出文件
OUTPUT_JSONL=$(find "$WORK_DIR/evaluation/evaluation_outputs" -name "output.jsonl" -path "*devstral*" | head -1)

if [ -n "$OUTPUT_JSONL" ]; then
    echo "📊 输出文件: $OUTPUT_JSONL" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "📈 最终统计:" | tee -a "$LOG_FILE"
    TOTAL=$(wc -l < "$OUTPUT_JSONL" 2>/dev/null || echo "0")
    echo "   完成实例数: $TOTAL" | tee -a "$LOG_FILE"
    
    # 统计有patch的实例
    if command -v python3 &> /dev/null; then
        PATCH_COUNT=$(python3 << 'PYEOF'
import json
import sys
try:
    with open(sys.argv[1], 'r') as f:
        count = 0
        for line in f:
            try:
                data = json.loads(line)
                if data.get('git_patch') and data.get('git_patch').strip():
                    count += 1
            except:
                pass
        print(count)
except:
    print(0)
PYEOF
        "$OUTPUT_JSONL" 2>/dev/null || echo "0")
        echo "   生成patch的实例数: $PATCH_COUNT" | tee -a "$LOG_FILE"
    fi
    echo "" | tee -a "$LOG_FILE"
    echo "💡 查看结果:" | tee -a "$LOG_FILE"
    echo "   - 日志: $LOG_FILE" | tee -a "$LOG_FILE"
    echo "   - 结果: $OUTPUT_JSONL" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"


