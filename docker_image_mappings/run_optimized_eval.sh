#!/bin/bash

# 设置代理
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7890

echo "========================================"
echo "Optimized评测 - 使用LM Studio Qwen3-14B和新配置"
echo "========================================"
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORK_DIR="$PROJECT_ROOT/OpenHands"
OPTIMIZED_DIR="$SCRIPT_DIR/optimized"
INSTANCE_LIST_FILE="$SCRIPT_DIR/已有镜像的实例列表.txt"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

cd "$WORK_DIR" || exit 1

# 创建optimized目录
mkdir -p "$OPTIMIZED_DIR"
mkdir -p "$OPTIMIZED_DIR/logs"
mkdir -p "$OPTIMIZED_DIR/results"

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
LOG_FILE="$OPTIMIZED_DIR/logs/evaluation_${TIMESTAMP}.log"
echo "📝 日志文件: $LOG_FILE"
echo ""

# 运行评测
echo "🚀 开始Optimized评测 (12个实例, LM Studio Qwen3-14B)..." | tee -a "$LOG_FILE"
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
    --eval-note \"optimized\" \
    --eval-ids \"$INSTANCE_IDS\""

# 执行命令并记录日志
echo "执行命令: $CMD" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# 设置环境变量供Python脚本使用
export OPTIMIZED_DIR="$OPTIMIZED_DIR"
export INSTANCE_LIST_FILE="$INSTANCE_LIST_FILE"

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
output_base = os.path.join(work_dir, "evaluation/evaluation_outputs/outputs")
dataset_name = "princeton-nlp__SWE-bench_Lite-test"
agent = "CodeActAgent"
model_config = "eval_vllm_remote"
max_iter = "25"
eval_note = "optimized"

# 构建可能的输出目录路径
possible_dirs = [
    f"{dataset_name}/{agent}/{model_config}_maxiter_{max_iter}_N_{eval_note}",
    f"{dataset_name}/{agent}/qwen3-14b_maxiter_{max_iter}_N_{eval_note}",
]

for dir_suffix in possible_dirs:
    output_dir = os.path.join(output_base, dir_suffix)
    output_file = os.path.join(output_dir, "output.jsonl")
    if os.path.exists(output_file):
        print(output_file)
        exit(0)

# 如果没找到，尝试查找最新的
if os.path.exists(output_base):
    for root, dirs, files in os.walk(output_base):
        if "output.jsonl" in files and "optimized" in root:
            print(os.path.join(root, "output.jsonl"))
            exit(0)

print("")
PYEOF
)

if [ -z "$OUTPUT_JSONL" ] || [ ! -f "$OUTPUT_JSONL" ]; then
    echo "❌ 未找到输出文件" | tee -a "$LOG_FILE"
    # 恢复配置文件
    if [ -n "$SWEBENCH_CONFIG_BACKUP" ] && [ -f "$SWEBENCH_CONFIG_BACKUP" ]; then
        echo "🔄 恢复配置文件..."
        mv "$SWEBENCH_CONFIG_BACKUP" "$SWEBENCH_CONFIG"
        echo "✅ 已恢复配置文件"
    fi
    exit 1
fi

echo "✅ 找到输出文件: $OUTPUT_JSONL" | tee -a "$LOG_FILE"

# 复制输出文件
cp "$OUTPUT_JSONL" "$OPTIMIZED_DIR/results/output.jsonl"
echo "✅ 已复制输出文件到: $OPTIMIZED_DIR/results/output.jsonl" | tee -a "$LOG_FILE"

# 复制LLM completions和conversations
OUTPUT_DIR=$(dirname "$OUTPUT_JSONL")
if [ -d "$OUTPUT_DIR/llm_completions" ]; then
    cp -r "$OUTPUT_DIR/llm_completions" "$OPTIMIZED_DIR/results/"
    echo "✅ 已复制LLM completions" | tee -a "$LOG_FILE"
fi
if [ -d "$OUTPUT_DIR/conversations" ]; then
    cp -r "$OUTPUT_DIR/conversations" "$OPTIMIZED_DIR/results/"
    echo "✅ 已复制conversations" | tee -a "$LOG_FILE"
fi

# 恢复配置文件
if [ -n "$SWEBENCH_CONFIG_BACKUP" ] && [ -f "$SWEBENCH_CONFIG_BACKUP" ]; then
    echo "🔄 恢复配置文件..."
    mv "$SWEBENCH_CONFIG_BACKUP" "$SWEBENCH_CONFIG"
    echo "✅ 已恢复配置文件"
fi

# 生成报告
echo "📊 生成报告..." | tee -a "$LOG_FILE"
OPTIMIZED_DIR="$OPTIMIZED_DIR" INSTANCE_LIST_FILE="$INSTANCE_LIST_FILE" python3 << PYEOF
import json
import os
import sys
from datetime import datetime

# 从环境变量获取路径
optimized_dir = os.environ.get('OPTIMIZED_DIR', '')
if not optimized_dir:
    print("错误: OPTIMIZED_DIR 环境变量未设置", file=sys.stderr)
    sys.exit(1)

output_file = os.path.join(optimized_dir, "results", "output.jsonl")
report_file = os.path.join(optimized_dir, "report.md")
instance_list_file = os.environ.get('INSTANCE_LIST_FILE', '')

if not os.path.exists(output_file):
    print(f"❌ 输出文件不存在: {output_file}")
    exit(1)

results = []
with open(output_file, 'r') as f:
    for line in f:
        if line.strip():
            try:
                results.append(json.loads(line))
            except json.JSONDecodeError:
                continue

print(f"总实例数: {len(results)}")

success_count = 0
success_list = []
failed_list = []

for r in results:
    instance_id = r.get('instance_id', 'unknown')
    patch = r.get('test_result', {}).get('git_patch', '')
    patch_len = len(patch) if patch else 0
    
    # 检查是否是有效的diff格式
    is_valid_patch = patch.startswith('diff --git') if patch else False
    
    if is_valid_patch:
        success_count += 1
        success_list.append(instance_id)
    else:
        failed_list.append(instance_id)

# 读取期望的实例列表
expected_instances = set()
if instance_list_file and os.path.exists(instance_list_file):
    with open(instance_list_file, 'r') as f:
        for line in f:
            inst = line.strip()
            if inst:
                expected_instances.add(inst)

run_instances = set(r.get('instance_id', '') for r in results)
missing_instances = expected_instances - run_instances

# 生成报告
report_content = f"""# Optimized评测结果报告

生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## 评测配置
- 模型: Qwen3-14B (LM Studio, 32K上下文窗口)
- Agent: CodeActAgent
- 最大迭代次数: 25
- 期望实例数: {len(expected_instances)}
- 实际运行实例数: {len(results)}

## 评测结果

### 总体统计
- 总实例数: {len(results)}
- 成功生成patch: {success_count} 个 ({(success_count/len(results)*100) if len(results) > 0 else 0:.1f}%)
- 未生成patch: {len(failed_list)} 个

### 详细结果

#### ✅ 成功生成patch的实例 ({success_count}个)
"""
for i, inst in enumerate(success_list, 1):
    report_content += f"{i}. ✅ **{inst}** - 生成了有效的git patch\n"

report_content += f"""
#### ❌ 未生成patch的实例 ({len(failed_list)}个)
"""
for i, inst in enumerate(failed_list, 1):
    report_content += f"{i}. ❌ {inst}\n"

if missing_instances:
    report_content += f"""
## ⚠️ 未运行的实例

以下实例在期望列表中但未运行（共{len(missing_instances)}个）:
"""
    for inst in sorted(missing_instances):
        report_content += f"- {inst}\n"

report_content += f"""
## 结果分析

### 成功率分析
- **总体成功率**: {success_count}/{len(results)} = **{(success_count/len(results)*100) if len(results) > 0 else 0:.1f}%**
- 使用LM Studio Qwen3-14B模型，32K上下文窗口

### 成功实例分析
"""
for inst in success_list:
    report_content += f"- `{inst}`: 成功生成了有效的patch\n"

report_content += f"""
### 失败实例分析
所有失败的实例都在25次迭代内未能生成有效的patch，可能原因：
1. 任务难度较高，需要更深入的理解
2. 需要更多的迭代次数或更优化的策略
3. 模型在某些特定任务上的表现限制

## 文件位置

- 结果文件: `optimized/results/output.jsonl`
- 日志文件: `optimized/logs/evaluation_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log`
- LLM对话记录: `optimized/results/llm_completions/`
- 完整对话记录: `optimized/results/conversations/`
"""

with open(report_file, 'w', encoding='utf-8') as f:
    f.write(report_content)

print(f"✅ 报告已生成: {report_file}")
PYEOF

echo ""
echo "========================================"
echo "✅ Optimized评测完成!"
echo "========================================"
echo "结果文件: $OPTIMIZED_DIR/results/output.jsonl"
echo "报告文件: $OPTIMIZED_DIR/report.md"
echo "日志文件: $LOG_FILE"
