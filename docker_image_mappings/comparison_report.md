# Baseline vs Optimized 评测对比报告

生成时间: 2025-11-24 06:22:57

## ⚠️ 重要说明

**当前统计的是 Patch 生成率，不是正确率！**

- **Patch 生成率**: 是否生成了格式正确的 git patch
- **正确率**: Patch 能否成功应用并通过测试（需要使用官方 SWE-Bench evaluation harness 验证）

要获得真正的正确率，需要运行官方评估工具：
```bash
# 评估 baseline
cd OpenHands
poetry run bash evaluation/benchmarks/swe_bench/scripts/eval_infer.sh \
    ../docker_image_mappings/baseline/results/output.jsonl \
    "" \
    "princeton-nlp/SWE-bench_Lite" \
    "test" \
    "local"

# 评估 optimized  
poetry run bash evaluation/benchmarks/swe_bench/scripts/eval_infer.sh \
    ../docker_image_mappings/optimized/results/output.jsonl \
    "" \
    "princeton-nlp/SWE-bench_Lite" \
    "test" \
    "local"
```

## Patch 生成率对比

| 指标 | Baseline | Optimized | 变化 |
|------|----------|-----------|------|
| 总实例数 | 9 | 9 | - |
| 成功生成patch | 2 | 4 | +2 |
| 未生成patch | 7 | 5 | -2 |
| **Patch生成率** | **22.2%** | **44.4%** | **+22.2%** |

**注意**: 两个评测均使用LM Studio Qwen3-14B模型（32K上下文窗口），但使用了不同的配置策略。

## 正确率对比

⚠️ **待评估** - 需要使用官方 SWE-Bench evaluation harness 运行测试验证

## 详细分析

### Patch生成成功率变化

- **Baseline Patch生成率**: 22.2%
- **Optimized Patch生成率**: 44.4%
- **提升**: +22.2% (⬆️ 提升)

### 实例对比

#### ✅ 共同成功生成patch的实例 (1个)

- django__django-13230

#### ⚠️  Baseline成功但Optimized失败的实例 (1个)

- psf__requests-2317

#### 🎯 Optimized成功但Baseline失败的实例 (3个)

- pallets__flask-4045
- pallets__flask-4992
- pallets__flask-5063

#### ❌ 共同失败的实例 (4个)

- psf__requests-1963
- psf__requests-2148
- scikit-learn__scikit-learn-25500
- sympy__sympy-18189

## 结论

✅ **Optimized配置显著提升了Patch生成率**，从 22.2% 提升到 44.4%，提升了 22.2 个百分点。

⚠️ **但Patch生成率 ≠ 正确率**，需要运行官方评估工具来验证：
- Patch能否成功应用到代码库
- 相关测试用例是否通过
- 是否真正解决了问题

## 下一步

1. 运行官方 SWE-Bench evaluation harness 验证patch正确性
2. 统计真正的正确率（通过测试的实例数 / 总实例数）
3. 对比Baseline和Optimized的正确率差异

## 文件位置

- Baseline结果: `docker_image_mappings/baseline/results/output.jsonl`
- Optimized结果: `docker_image_mappings/optimized/results/output.jsonl`
- Baseline报告: `docker_image_mappings/baseline/report.md`
- Optimized报告: `docker_image_mappings/optimized/report.md`
