# SWE-Bench评测配置指南

## 什么是SWE-Bench?

SWE-Bench (Software Engineering Benchmark) 是一个用于评估大语言模型在真实软件工程任务上表现的基准测试集。它包含：

- **SWE-bench Lite**: 300个精选的GitHub issue（轻量级测试集）
- **SWE-bench Verified**: 500个经过验证的高质量issue
- **SWE-bench Full**: 2,294个来自真实GitHub仓库的issue

每个任务要求模型：
1. 理解问题描述
2. 定位相关代码
3. 生成修复补丁
4. 通过相关测试

## 评测准备

### 1. 环境要求

最低配置：
- Python 3.12+
- 16GB RAM
- 50GB+ 磁盘空间
- 本地LLM服务 (Ollama/vLLM)

推荐配置：
- Python 3.12+
- 32GB+ RAM
- 200GB+ 磁盘空间 (用于Docker镜像)
- NVIDIA GPU (16GB+ VRAM)
- Docker (可选，用于完整评测)

### 2. 安装核心依赖

```bash
cd /Users/bitfun/codes/closehands/OpenHands

# 安装核心Python包 (如果完整build失败)
pip install litellm openai aiohttp datasets pandas toml jinja2
pip install anthropic tenacity tiktoken
pip install browsergym-core playwright

# 安装OpenHands核心包
pip install -e .
```

### 3. 配置本地模型

确保已按照 `setup_local_model.md` 配置好本地模型。验证：

```bash
# 测试Ollama
curl http://localhost:11434/api/tags

# 或测试vLLM
curl http://localhost:8000/v1/models
```

## 快速开始评测

### 方案A: 轻量级评测 (推荐用于快速测试)

不使用Docker，直接在本地环境运行：

```bash
cd /Users/bitfun/codes/closehands/OpenHands

# 设置环境变量
export INSTALL_DOCKER=0
export RUNTIME=local
export EVAL_LIMIT=5  # 先测试5个实例

# 运行评测 (使用SWE-bench Lite的前5个实例)
python evaluation/benchmarks/swe_bench/run_infer.py \
    --agent-cls CodeActAgent \
    --llm-config eval_local_model \
    --max-iterations 50 \
    --eval-num-workers 1 \
    --dataset-name "princeton-nlp/SWE-bench_Lite" \
    --split test \
    --eval-n-limit 5
```

### 方案B: 使用脚本运行评测

```bash
cd /Users/bitfun/codes/closehands/OpenHands

# 使用提供的脚本 (需要先确保有可用的Docker)
export INSTALL_DOCKER=0
./evaluation/benchmarks/swe_bench/scripts/run_infer.sh \
    eval_local_model \
    HEAD \
    CodeActAgent \
    5 \
    50 \
    1 \
    "princeton-nlp/SWE-bench_Lite" \
    test
```

## 自定义评测配置

### 1. 创建评测配置文件

创建 `evaluation/benchmarks/swe_bench/config.toml`:

```toml
# 选择特定的instance IDs进行评测
selected_ids = [
    'django__django-11001',
    'django__django-11019',
    'pylint-dev__pylint-7114'
]

# 或者留空以评测所有
# selected_ids = []
```

### 2. 环境变量配置

```bash
# 基础配置
export EVAL_LIMIT=10  # 评测实例数量
export MAX_ITERATIONS=100  # 每个实例的最大迭代次数
export NUM_WORKERS=1  # 并行worker数量

# 高级配置
export USE_HINT_TEXT=false  # 是否使用提示文本
export ENABLE_LLM_EDITOR=false  # 是否启用LLM编辑器
export ITERATIVE_EVAL_MODE=true  # 启用迭代评测模式 (更稳定)

# Condenser配置 (用于管理长对话历史)
export EVAL_CONDENSER=optimized_condenser

# 自定义提示模板
# export INSTRUCTION_TEMPLATE_NAME=swe_custom.j2
```

### 3. 自定义提示模板

创建 `evaluation/benchmarks/swe_bench/prompts/swe_custom.j2`:

```jinja2
You are an expert software engineer tasked with fixing a GitHub issue.

## Issue Description
{{ problem_statement }}

## Repository Information
- Repository: {{ repo }}
- Version: {{ version }}

## Your Task
1. Carefully analyze the issue description
2. Locate the relevant code files
3. Understand the root cause
4. Generate a minimal fix that addresses the issue
5. Ensure the fix doesn't break existing functionality

## Instructions
- Use the bash tool to explore the repository
- Use the edit tool to modify files
- Run tests to verify your fix
- When done, use the finish tool with your patch

Please proceed step by step.
```

## 评测数据集选择

### SWE-bench Lite (推荐用于初始测试)

```bash
# 最小测试集 - 300个实例
DATASET="princeton-nlp/SWE-bench_Lite"
```

优点：
- 规模小，评测快
- 精选的高质量issue
- 适合快速迭代

### SWE-bench Verified

```bash
# 验证测试集 - 500个实例
DATASET="princeton-nlp/SWE-bench_Verified"
```

优点：
- 经过验证的高质量数据
- 平衡的难度分布
- 适合正式评测

### SWE-bench Full

```bash
# 完整测试集 - 2,294个实例
DATASET="princeton-nlp/SWE-bench"
```

注意：
- 规模大，需要大量时间和资源
- 仅用于最终评测

## 评测输出

评测结果将保存在：
```
evaluation/evaluation_outputs/outputs/
    princeton-nlp__SWE-bench_Lite/
        CodeActAgent/
            eval_local_model_maxiter_50_N_v1.0/
                output.jsonl          # 原始输出
                trajectory.jsonl      # 完整轨迹
                metrics.json          # 评测指标
                README.md            # 评测报告
```

### 输出文件说明

1. **output.jsonl**: 每行一个JSON对象
   ```json
   {
       "instance_id": "django__django-11001",
       "model_patch": "diff --git a/...",
       "model_name_or_path": "eval_local_model",
       "test_result": "passed/failed"
   }
   ```

2. **trajectory.jsonl**: 完整的agent行为轨迹
   - 所有的actions和observations
   - 用于调试和分析

3. **metrics.json**: 评测指标
   ```json
   {
       "resolved_rate": 0.45,
       "resolved_ids": ["django__django-11001", ...],
       "failed_ids": ["django__django-11019", ...],
       "total_cost": 12.5,
       "avg_iterations": 35.2
   }
   ```

## 评测结果分析

### 查看解决的问题

```bash
cd evaluation/evaluation_outputs/outputs/...

# 查看解决的instance IDs
grep '"test_result": "passed"' output.jsonl | jq -r '.instance_id'
```

### 分析失败原因

```bash
# 查看失败的实例
grep '"test_result": "failed"' output.jsonl | jq -r '.instance_id'

# 查看specific实例的轨迹
python -m evaluation.benchmarks.swe_bench.scripts.analyze_trajectory \
    --trajectory trajectory.jsonl \
    --instance-id django__django-11001
```

### 计算指标

```bash
# 计算解决率
python evaluation/benchmarks/swe_bench/scripts/calculate_metrics.py \
    --output-file output.jsonl
```

## 常见问题

### Q1: 评测运行很慢怎么办？

A: 
1. 减少EVAL_LIMIT
2. 使用更小的模型
3. 减少MAX_ITERATIONS
4. 启用caching_prompt

### Q2: 内存不足怎么办？

A:
1. 使用量化模型 (q4_0, q5_0)
2. 减少max_input_tokens
3. 启用history truncation
4. 使用condenser管理历史

### Q3: 如何提高解决率？

A: 参考 `optimization_strategies.md` 中的优化方案

### Q4: 评测中断了怎么办？

A: 
```bash
# OpenHands会自动跳过已完成的实例
# 重新运行相同的命令即可继续
```

### Q5: 如何对比不同配置？

A:
```bash
# 运行baseline
python run_infer.py --llm-config eval_local_model --eval-n-limit 10

# 运行优化版本
python run_infer.py --llm-config eval_local_model_optimized --eval-n-limit 10

# 对比结果
python scripts/compare_results.py \
    --baseline baseline_output.jsonl \
    --optimized optimized_output.jsonl
```

## 最佳实践

1. **先小规模测试**: 使用5-10个实例验证配置
2. **逐步扩大**: 成功后扩展到50个实例
3. **保存轨迹**: 启用trajectory保存以便分析
4. **版本控制**: 记录每次评测的配置和版本
5. **资源监控**: 监控CPU/GPU/内存使用
6. **定期检查点**: 对长时间评测设置检查点

## 下一步

1. 完成本地模型配置 (setup_local_model.md)
2. 运行baseline评测 (本文档)
3. 应用优化策略 (optimization_strategies.md)
4. 对比并生成报告

## 参考资源

- SWE-Bench官方网站: https://www.swebench.com/
- SWE-Bench GitHub: https://github.com/princeton-nlp/SWE-bench
- OpenHands文档: https://docs.openhands.dev/
- 评测排行榜: https://www.swebench.com/leaderboard

