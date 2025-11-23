#!/bin/bash
# 等待 gpt-oss-20b 下载完成并运行测试

set -e

# 设置代理
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7890

echo "========================================"
echo "等待 gpt-oss-20b 下载完成并运行测试"
echo "========================================"
echo ""

MODEL_NAME="gpt-oss:20b"
MAX_WAIT_TIME=3600  # 最大等待时间：1小时
CHECK_INTERVAL=30   # 每30秒检查一次

# 检查模型是否已下载
check_model() {
    ollama list 2>/dev/null | grep -q "$MODEL_NAME"
}

# 检查下载是否在进行中
check_downloading() {
    # 检查是否有 ollama pull 进程
    ps aux | grep -v grep | grep -q "ollama pull.*gpt-oss"
}

echo "正在检查模型状态..."
echo ""

# 如果模型已存在，直接运行测试
if check_model; then
    echo "✅ 模型已下载完成！"
    echo ""
else
    echo "⏳ 模型未找到，检查是否正在下载..."
    
    if check_downloading; then
        echo "✅ 检测到下载进程正在运行"
        echo "   等待下载完成..."
        echo ""
        
        START_TIME=$(date +%s)
        while [ $(($(date +%s) - START_TIME)) -lt $MAX_WAIT_TIME ]; do
            if check_model; then
                echo ""
                echo "✅ 模型下载完成！"
                break
            fi
            
            # 检查下载进程是否还在运行
            if ! check_downloading; then
                # 再次检查模型是否存在（可能下载已完成但进程已结束）
                sleep 5
                if check_model; then
                    echo ""
                    echo "✅ 模型下载完成！"
                    break
                else
                    echo ""
                    echo "❌ 下载进程已结束，但模型未找到"
                    echo "   请手动检查: ollama list"
                    exit 1
                fi
            fi
            
            ELAPSED=$(($(date +%s) - START_TIME))
            MINUTES=$((ELAPSED / 60))
            SECONDS=$((ELAPSED % 60))
            printf "\r⏳ 等待中... (已等待 %02d:%02d)" $MINUTES $SECONDS
            
            sleep $CHECK_INTERVAL
        done
        
        if [ $(($(date +%s) - START_TIME)) -ge $MAX_WAIT_TIME ]; then
            echo ""
            echo "❌ 等待超时（超过1小时）"
            echo "   请手动检查下载状态: ollama list"
            exit 1
        fi
    else
        echo "❌ 未检测到下载进程"
        echo "   开始下载模型..."
        echo ""
        
        # 在后台启动下载
        ollama pull "$MODEL_NAME" > /tmp/ollama_gpt_oss_download.log 2>&1 &
        DOWNLOAD_PID=$!
        
        echo "✅ 下载已启动 (PID: $DOWNLOAD_PID)"
        echo "   日志文件: /tmp/ollama_gpt_oss_download.log"
        echo "   等待下载完成..."
        echo ""
        
        START_TIME=$(date +%s)
        while [ $(($(date +%s) - START_TIME)) -lt $MAX_WAIT_TIME ]; do
            # 检查进程是否还在运行
            if ! ps -p $DOWNLOAD_PID > /dev/null 2>&1; then
                # 进程已结束，检查模型是否存在
                sleep 5
                if check_model; then
                    echo ""
                    echo "✅ 模型下载完成！"
                    break
                else
                    echo ""
                    echo "❌ 下载进程已结束，但模型未找到"
                    echo "   请查看日志: tail -50 /tmp/ollama_gpt_oss_download.log"
                    exit 1
                fi
            fi
            
            ELAPSED=$(($(date +%s) - START_TIME))
            MINUTES=$((ELAPSED / 60))
            SECONDS=$((ELAPSED % 60))
            printf "\r⏳ 下载中... (已等待 %02d:%02d)" $MINUTES $SECONDS
            
            sleep $CHECK_INTERVAL
        done
        
        if [ $(($(date +%s) - START_TIME)) -ge $MAX_WAIT_TIME ]; then
            echo ""
            echo "❌ 等待超时（超过1小时）"
            echo "   下载可能仍在进行，请稍后手动检查: ollama list"
            exit 1
        fi
    fi
fi

echo ""
echo "========================================"
echo "开始运行测试 (2个用例)"
echo "========================================"
echo ""

cd "$(dirname "$0")/OpenHands" || exit 1

# 检查 Ollama 服务
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "❌ Ollama 服务未运行"
    echo "   请先启动 Ollama: ollama serve"
    exit 1
fi

# 测试配置
MODEL_CONFIG="eval_local_model_gpt_oss_20b"
AGENT="CodeActAgent"
EVAL_LIMIT=2
MAX_ITER=25
NUM_WORKERS=1
DATASET_SPLIT="test"
DATASET="princeton-nlp/SWE-bench_Lite"

echo "测试参数:"
echo "  模型: gpt-oss-20b"
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
echo ""

START_TIME=$(date +%s)
LOG_FILE="../test_gpt_oss_20b_2instances_$(date +%Y%m%d_%H%M%S).log"

# 运行评测
poetry run python evaluation/benchmarks/swe_bench/run_infer.py \
    --llm-config "$MODEL_CONFIG" \
    --agent-cls "$AGENT" \
    --max-iterations "$MAX_ITER" \
    --eval-num-workers "$NUM_WORKERS" \
    --eval-n-limit "$EVAL_LIMIT" \
    --data-split "$DATASET_SPLIT" \
    --dataset-name "$DATASET" \
    2>&1 | tee "$LOG_FILE"

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
    
    print("\n  详细结果:")
    for i, r in enumerate(results, 1):
        instance_id = r.get('instance_id', 'unknown')
        has_patch = bool(r.get('test_result', {}).get('git_patch', '').strip())
        status = "✅ 成功" if has_patch else "❌ 失败"
        error = r.get('error', '')
        print(f"    {i}. {instance_id}: {status}")
        if error and not has_patch:
            error_short = error[:150] if len(error) > 150 else error
            print(f"       错误: {error_short}")
except Exception as e:
    print(f"  解析结果时出错: {e}")
PYEOF
    "$OUTPUT_FILE"
else
    echo "⚠️  结果文件未找到: $OUTPUT_FILE"
fi

echo ""
echo "结果文件: $OUTPUT_FILE"
echo "日志文件: $LOG_FILE"
echo ""

