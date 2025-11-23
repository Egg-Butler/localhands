#!/bin/bash

# 设置代理
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7890

echo "========================================"
echo "Baseline评测 - 使用已有Docker镜像的12个实例"
echo "========================================"
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORK_DIR="$PROJECT_ROOT/OpenHands"
BASELINE_DIR="$SCRIPT_DIR/baseline"
INSTANCE_LIST_FILE="$SCRIPT_DIR/已有镜像的实例列表.txt"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

cd "$WORK_DIR" || exit 1

# 创建baseline目录
mkdir -p "$BASELINE_DIR"
mkdir -p "$BASELINE_DIR/logs"
mkdir -p "$BASELINE_DIR/results"

# 临时禁用selected_ids配置（如果存在）
SWEBENCH_CONFIG="$WORK_DIR/evaluation/benchmarks/swe_bench/config.toml"
SWEBENCH_CONFIG_BACKUP=""
if [ -f "$SWEBENCH_CONFIG" ]; then
    # 检查是否有selected_ids配置
    if grep -q "selected_ids" "$SWEBENCH_CONFIG"; then
        echo "⚠️  发现selected_ids配置，将临时重命名配置文件..."
        SWEBENCH_CONFIG_BACKUP="${SWEBENCH_CONFIG}.backup_${TIMESTAMP}"
        mv "$SWEBENCH_CONFIG" "$SWEBENCH_CONFIG_BACKUP"
        echo "✅ 已临时禁用selected_ids配置（配置文件已重命名）"
    fi
fi

# 读取实例ID列表
INSTANCE_IDS=$(grep -v '^$' "$INSTANCE_LIST_FILE" | tr '\n' ',' | sed 's/,$//')
echo "📋 实例列表: $INSTANCE_IDS"
echo ""

# 评测配置
MODEL_CONFIG="eval_lmstudio_qwen3_14b"  # 使用LM Studio Qwen3-14B
AGENT="CodeActAgent"
MAX_ITER=25
NUM_WORKERS=1
DATASET="princeton-nlp/SWE-bench_Lite"
DATASET_SPLIT="test"

# 设置环境变量
export WORKSPACE_BASE="$WORK_DIR/workspace"
export CACHE_DIR="$WORK_DIR/cache"

# 日志文件
LOG_FILE="$BASELINE_DIR/logs/evaluation_${TIMESTAMP}.log"
echo "📝 日志文件: $LOG_FILE"
echo ""

# 运行评测
echo "🚀 开始Baseline评测 (12个实例, LM Studio Qwen3-14B)..." | tee -a "$LOG_FILE"
echo "配置: $MODEL_CONFIG" | tee -a "$LOG_FILE"
echo "模型: Qwen3-14B (LM Studio, 32K上下文)" | tee -a "$LOG_FILE"
echo "实例ID: $INSTANCE_IDS" | tee -a "$LOG_FILE"
echo ""

# 构建命令
CMD="poetry run python evaluation/benchmarks/swe_bench/run_infer.py \
    --llm-config \"$MODEL_CONFIG\" \
    --agent-cls \"$AGENT\" \
    --max-iterations \"$MAX_ITER\" \
    --eval-num-workers \"$NUM_WORKERS\" \
    --split \"$DATASET_SPLIT\" \
    --dataset \"$DATASET\" \
    --eval-note \"baseline\" \
    --eval-ids \"$INSTANCE_IDS\""

# 执行命令并记录日志
echo "执行命令: $CMD" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

eval $CMD 2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}
echo ""
echo "========================================"
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ 测试完成!"
else
    echo "⚠️  测试中断或失败 (退出码: $EXIT_CODE)"
fi
echo "========================================"
echo ""

# 查找输出文件
echo "📊 查找输出文件..." | tee -a "$LOG_FILE"
OUTPUT_JSONL=$(python3 << 'PYEOF'
import os
import json
from pathlib import Path

work_dir = os.environ.get('WORK_DIR', '.')
eval_outputs_dir = os.path.join(work_dir, 'evaluation/evaluation_outputs')

# 查找所有可能的输出目录
for root, dirs, files in os.walk(eval_outputs_dir):
    # 检查是否有output.jsonl和metadata.json文件
    output_file = os.path.join(root, 'output.jsonl')
    metadata_file = os.path.join(root, 'metadata.json')
    
    if os.path.exists(output_file) and os.path.exists(metadata_file):
        try:
            with open(metadata_file, 'r') as f:
                metadata = json.load(f)
                llm_config = metadata.get('llm_config', {})
                # 检查是否是baseline配置
                if 'baseline' in root.lower():
                    model = llm_config.get('model', '')
                    if 'qwen3-14b' in model.lower() or 'qwen3_14b' in model.lower():
                        print(output_file)
                        exit(0)
        except Exception as e:
            pass

exit(1)
PYEOF
WORK_DIR="$WORK_DIR"
)

if [ -n "$OUTPUT_JSONL" ] && [ -f "$OUTPUT_JSONL" ]; then
    echo "✅ 找到输出文件: $OUTPUT_JSONL" | tee -a "$LOG_FILE"
    
    # 复制输出文件到baseline目录
    cp "$OUTPUT_JSONL" "$BASELINE_DIR/results/output.jsonl"
    echo "✅ 已复制输出文件到: $BASELINE_DIR/results/output.jsonl" | tee -a "$LOG_FILE"
    
    # 只复制output.jsonl中实际存在的实例对应的目录
    OUTPUT_DIR=$(dirname "$OUTPUT_JSONL")
    
    # 提取output.jsonl中的实例ID列表
    INSTANCE_IDS_IN_OUTPUT=$(python3 << 'PYEOF'
import json
import sys
output_file = sys.argv[1]
instance_ids = []
try:
    with open(output_file, 'r') as f:
        for line in f:
            if line.strip():
                try:
                    data = json.loads(line)
                    instance_id = data.get('instance_id', '')
                    if instance_id:
                        instance_ids.append(instance_id)
                except:
                    pass
    print(' '.join(instance_ids))
except Exception as e:
    print('', file=sys.stderr)
    sys.exit(1)
PYEOF
    "$OUTPUT_JSONL"
    )
    
    # 复制LLM completions（只复制output.jsonl中存在的实例）
    if [ -d "$OUTPUT_DIR/llm_completions" ]; then
        mkdir -p "$BASELINE_DIR/results/llm_completions"
        for instance_id in $INSTANCE_IDS_IN_OUTPUT; do
            if [ -d "$OUTPUT_DIR/llm_completions/$instance_id" ]; then
                cp -r "$OUTPUT_DIR/llm_completions/$instance_id" "$BASELINE_DIR/results/llm_completions/" 2>/dev/null || true
            fi
        done
        echo "✅ 已复制LLM completions（仅包含output.jsonl中的实例）" | tee -a "$LOG_FILE"
    fi
    
    # 复制conversations（只复制output.jsonl中存在的实例）
    if [ -d "$OUTPUT_DIR/conversations" ]; then
        mkdir -p "$BASELINE_DIR/results/conversations"
        for instance_id in $INSTANCE_IDS_IN_OUTPUT; do
            if [ -d "$OUTPUT_DIR/conversations/$instance_id" ]; then
                cp -r "$OUTPUT_DIR/conversations/$instance_id" "$BASELINE_DIR/results/conversations/" 2>/dev/null || true
            fi
        done
        echo "✅ 已复制conversations（仅包含output.jsonl中的实例）" | tee -a "$LOG_FILE"
    fi
    
    # 生成报告
    echo "📊 生成报告..." | tee -a "$LOG_FILE"
    python3 << 'PYEOF'
import json
import sys
from pathlib import Path
from datetime import datetime

output_file = sys.argv[1]
report_file = sys.argv[2]

results = []
with open(output_file, 'r') as f:
    for line in f:
        if line.strip():
            try:
                data = json.loads(line)
                results.append(data)
            except:
                pass

total = len(results)
patches = [r for r in results if r.get('test_result', {}).get('git_patch', '').strip()]
patch_count = len(patches)
success_rate = (patch_count / total * 100) if total > 0 else 0

report = f"""# Baseline评测结果报告

生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## 评测配置
- 模型: Qwen3-14B (LM Studio, 32K上下文)
- Agent: CodeActAgent
- 最大迭代次数: 25
- 实例数量: {total}

## 评测结果

### 总体统计
- 总实例数: {total}
- 生成patch: {patch_count} ({success_rate:.1f}%)
- 未生成patch: {total - patch_count}

### 详细结果

"""
for i, r in enumerate(results, 1):
    instance_id = r.get('instance_id', 'unknown')
    patch = r.get('test_result', {}).get('git_patch', '')
    has_patch = bool(patch.strip())
    status = "✅ 有patch" if has_patch else "❌ 无patch"
    patch_len = len(patch)
    report += f"{i}. {status} {instance_id} (patch长度: {patch_len})\n"

report += f"""
## 实例列表
"""
for r in results:
    instance_id = r.get('instance_id', 'unknown')
    patch = r.get('test_result', {}).get('git_patch', '')
    has_patch = bool(patch.strip())
    status = "✅" if has_patch else "❌"
    report += f"- {status} {instance_id}\n"

with open(report_file, 'w', encoding='utf-8') as f:
    f.write(report)

print(f"✅ 报告已生成: {report_file}")
PYEOF
    "$BASELINE_DIR/results/output.jsonl" "$BASELINE_DIR/report.md"
    
    echo ""
    echo "========================================"
    echo "✅ Baseline评测完成!"
    echo "========================================"
    echo "结果文件: $BASELINE_DIR/results/output.jsonl"
    echo "报告文件: $BASELINE_DIR/report.md"
    echo "日志文件: $LOG_FILE"
    echo ""
else
    echo "⚠️  未找到输出文件" | tee -a "$LOG_FILE"
    exit 1
fi

# 恢复配置文件（如果之前备份了）
if [ -n "$SWEBENCH_CONFIG_BACKUP" ] && [ -f "$SWEBENCH_CONFIG_BACKUP" ]; then
    echo "🔄 恢复配置文件..."
    mv "$SWEBENCH_CONFIG_BACKUP" "$SWEBENCH_CONFIG"
    echo "✅ 已恢复配置文件"
fi

