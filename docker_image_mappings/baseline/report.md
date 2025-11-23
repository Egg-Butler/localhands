# Baseline评测结果报告

生成时间: 2025-11-24 03:22:16

## 评测配置
- 模型: Qwen3-14B (LM Studio, 32K上下文窗口)
- Agent: CodeActAgent
- 最大迭代次数: 25
- 期望实例数: 12
- 实际运行实例数: 9

## 评测结果

### 总体统计
- 总实例数: 9
- 成功生成patch: 2 个 (22.2%)
- 未生成patch: 7 个

### 详细结果

#### ✅ 成功生成patch的实例 (2个)
1. ✅ **django__django-13230** - 生成了有效的git patch
2. ✅ **psf__requests-2317** - 生成了有效的git patch

#### ❌ 未生成patch的实例 (7个)
1. ❌ pallets__flask-4045
2. ❌ pallets__flask-4992
3. ❌ pallets__flask-5063
4. ❌ psf__requests-1963
5. ❌ psf__requests-2148
6. ❌ scikit-learn__scikit-learn-25500
7. ❌ sympy__sympy-18189

## ⏱️ 性能统计

- **总耗时**: 39分40秒 (2380秒)
- **平均每个实例**: 约264秒 (4.4分钟)
- **最快实例**: 约2-3分钟（Docker镜像已缓存的情况）
- **最慢实例**: 约5-6分钟（需要构建Docker镜像的情况）

## ⚠️ 未运行的实例

以下实例在期望列表中但未运行（共3个）:
- django__django-11532
- astropy__astropy-11693
- pydata__xarray-6804

**说明**: 这3个实例可能因为Docker镜像构建失败或其他原因未运行。

## 结果分析

### 成功率分析
- **总体成功率**: 2/9 = **22.2%**
- 这个成功率相对较低，可能的原因：
  1. 部分任务需要更复杂的推理和多次迭代
  2. 部分任务需要更复杂的推理和多次迭代
  3. 某些任务可能需要特定的代码库知识或测试执行策略

### 成功实例分析
- `django__django-13230`: 成功生成了关于`item_comments`的patch
- `psf__requests-2317`: 成功生成了关于`method`参数处理的patch

### 失败实例分析
所有失败的实例都在25次迭代内未能生成有效的patch，可能原因：
1. 任务难度较高，需要更深入的理解
2. 需要更多的迭代次数或更优化的策略
3. 模型在某些特定任务上的表现限制

## 建议

1. **检查详细日志**: 查看`llm_completions/`和`conversations/`目录了解模型的具体行为
2. **分析成功案例**: 深入研究成功实例的对话过程，找出成功的关键因素
3. **优化策略**: 
   - 考虑增加`max_iterations`参数
   - 优化prompt策略
   - 分析失败案例，优化模型调用策略
4. **完成剩余实例**: 运行剩余的3个未运行实例以完成完整评测

## 文件位置

- 结果文件: `baseline/results/output.jsonl`
- 日志文件: `baseline/logs/evaluation_20251124_024220.log`
- LLM对话记录: `baseline/results/llm_completions/`
- 完整对话记录: `baseline/results/conversations/`
