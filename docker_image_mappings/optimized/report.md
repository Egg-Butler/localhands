# Optimized评测结果报告

生成时间: 2025-11-24 05:42:14

## 评测配置
- 模型: Qwen3-14B (LM Studio, 32K上下文窗口)
- Agent: CodeActAgent
- 最大迭代次数: 25
- 期望实例数: 12
- 实际运行实例数: 9

## 评测结果

### 总体统计
- 总实例数: 9
- 成功生成patch: 4 个 (44.4%)
- 未生成patch: 5 个

### 详细结果

#### ✅ 成功生成patch的实例 (4个)
1. ✅ **django__django-13230** - 生成了有效的git patch
2. ✅ **pallets__flask-4045** - 生成了有效的git patch
3. ✅ **pallets__flask-4992** - 生成了有效的git patch
4. ✅ **pallets__flask-5063** - 生成了有效的git patch

#### ❌ 未生成patch的实例 (5个)
1. ❌ psf__requests-1963
2. ❌ psf__requests-2148
3. ❌ psf__requests-2317
4. ❌ scikit-learn__scikit-learn-25500
5. ❌ sympy__sympy-18189

## ⚠️ 未运行的实例

以下实例在期望列表中但未运行（共3个）:
- astropy__astropy-11693
- django__django-11532
- pydata__xarray-6804

## 结果分析

### 成功率分析
- **总体成功率**: 4/9 = **44.4%**
- 使用LM Studio Qwen3-14B模型，32K上下文窗口

### 成功实例分析
- : 成功生成了有效的patch
- : 成功生成了有效的patch
- : 成功生成了有效的patch
- : 成功生成了有效的patch

### 失败实例分析
所有失败的实例都在25次迭代内未能生成有效的patch，可能原因：
1. 任务难度较高，需要更深入的理解
2. 需要更多的迭代次数或更优化的策略
3. 模型在某些特定任务上的表现限制

## 文件位置

- 结果文件: 
- 日志文件: 
- LLM对话记录: 
- 完整对话记录: 
