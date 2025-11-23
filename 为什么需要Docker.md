# 为什么 SWE-Bench 评测需要 Docker？

## 🤔 问题分析

### 为什么需要 Docker？

SWE-Bench 评测需要 Docker 的原因主要有以下几点：

#### 1. **隔离的测试环境** 🔒

每个 SWE-Bench 实例需要：
- **独立的代码库环境**: 每个实例对应一个特定的 GitHub 仓库和 commit
- **特定的依赖版本**: 需要安装特定版本的 Python 包、系统库等
- **隔离的执行环境**: 避免不同实例之间的干扰

**示例**:
```
实例 1: django/django (commit abc123) → 需要 Django 3.2, Python 3.9
实例 2: flask/flask (commit def456) → 需要 Flask 2.0, Python 3.10
```

如果不用 Docker，这些环境会互相冲突！

#### 2. **运行真实的测试用例** 🧪

SWE-Bench 的评估需要：
- 运行项目**真实的测试套件**
- 验证修复是否**真正解决了问题**
- 确保测试在**正确的环境**中运行

**为什么不能简单运行测试？**
- 每个项目的测试环境不同
- 需要特定的系统依赖、数据库、服务等
- 需要确保环境与原始 issue 报告时一致

#### 3. **环境一致性** 📦

SWE-Bench 官方使用 Docker 镜像来确保：
- 所有评测者使用**相同的环境**
- 结果**可复现**和**可对比**
- 符合**官方评测标准**

#### 4. **安全性** 🛡️

- 代码可能包含恶意内容
- 测试可能修改系统文件
- Docker 提供**沙箱隔离**

---

## 🔍 技术细节

### SWE-Bench 的工作流程

```
1. 下载特定实例的 Docker 镜像
   ↓
2. 在容器中克隆代码库到特定 commit
   ↓
3. Agent 在容器中修改代码
   ↓
4. 在容器中运行测试验证修复
   ↓
5. 提取 git patch 作为结果
```

### Docker 镜像的作用

每个 SWE-Bench 实例都有对应的 Docker 镜像，例如：
- `sweb.eval.x86_64.django_1776_django-13230`
- 包含：代码库、依赖、测试环境、验证脚本

---

## 💡 是否有替代方案？

### 方案 1: 使用 Local Runtime (理论上可行,但不推荐)

OpenHands **确实支持** Local Runtime，但有以下限制：

#### ✅ 优点
- 不需要 Docker
- 运行速度可能更快
- 资源占用更少

#### ❌ 缺点
1. **环境冲突**: 不同实例需要不同的依赖版本
2. **无法运行测试**: 无法在正确环境中验证修复
3. **不符合标准**: 结果无法与官方评测对比
4. **安全性问题**: 代码直接在主机运行

#### 如何尝试 (不推荐)

```bash
# 设置环境变量使用 local runtime
export RUNTIME=local

# 运行评测
./quick_test_7b_10min.sh
```

**注意**: 这只能生成代码修复，**无法运行测试验证**！

---

### 方案 2: 使用 Remote Runtime (需要 API key)

OpenHands 支持远程 Runtime，在云端运行：

```bash
ALLHANDS_API_KEY="YOUR-KEY" \
RUNTIME=remote \
SANDBOX_REMOTE_RUNTIME_API_URL="https://runtime.eval.all-hands.dev" \
./quick_test_7b_10min.sh
```

**优点**: 不需要本地 Docker
**缺点**: 需要申请 API key，可能有使用限制

---

### 方案 3: 简化评测 (只生成代码,不运行测试)

可以修改评测流程，只生成代码修复，不运行测试：

#### 修改后的流程

```
1. Agent 分析问题
   ↓
2. Agent 生成代码修复
   ↓
3. 提取 git patch
   ↓
4. 保存结果 (不运行测试)
```

**优点**: 不需要 Docker
**缺点**: 
- 无法验证修复是否正确
- 无法计算 Resolved Rate
- 结果不完整

---

## 📊 对比分析

| 方案 | 需要 Docker | 可运行测试 | 结果完整性 | 推荐度 |
|------|------------|-----------|-----------|--------|
| **Docker Runtime** | ✅ 是 | ✅ 是 | ✅ 完整 | ⭐⭐⭐⭐⭐ |
| Local Runtime | ❌ 否 | ❌ 否 | ⚠️ 不完整 | ⭐⭐ |
| Remote Runtime | ❌ 否 | ✅ 是 | ✅ 完整 | ⭐⭐⭐⭐ |
| 简化评测 | ❌ 否 | ❌ 否 | ⚠️ 不完整 | ⭐ |

---

## 🎯 推荐方案

### 对于完整评测 (推荐)

**使用 Docker Runtime**:
1. 安装 Docker Desktop
2. 启动 Docker
3. 运行评测

**理由**:
- ✅ 结果完整可靠
- ✅ 符合官方标准
- ✅ 可以验证修复
- ✅ 结果可复现

### 对于快速验证 (临时方案)

**使用 Local Runtime + 简化流程**:
1. 只生成代码修复
2. 不运行测试
3. 手动检查代码质量

**理由**:
- ✅ 快速验证环境
- ✅ 不需要 Docker
- ⚠️ 结果不完整

---

## 🔧 实际代码分析

### SWE-Bench 评测脚本的关键代码

```python
# run_infer.py 第 640 行
runtime = create_runtime(config)  # 根据 config.runtime 创建

# 第 237 行
runtime=os.environ.get('RUNTIME', 'docker')  # 默认是 'docker'
```

### 可以修改的地方

1. **设置环境变量**:
   ```bash
   export RUNTIME=local  # 使用 local runtime
   ```

2. **修改配置文件**:
   ```toml
   [core]
   runtime = "local"  # 已在 config.toml 中设置
   ```

3. **但问题在于**: SWE-Bench 需要特定的 Docker 镜像来运行测试！

---

## 📝 总结

### 为什么一定要用 Docker？

1. **技术原因**: 
   - 需要隔离的测试环境
   - 需要运行真实的测试用例
   - 需要环境一致性

2. **标准原因**:
   - 符合 SWE-Bench 官方评测标准
   - 结果可复现和可对比

3. **安全原因**:
   - 代码隔离
   - 防止系统污染

### 替代方案

| 方案 | 适用场景 | 限制 |
|------|---------|------|
| Docker | 完整评测 | 需要安装 Docker |
| Local | 快速验证 | 无法运行测试 |
| Remote | 云端评测 | 需要 API key |

### 建议

**对于面试作业**:
1. **如果有 Docker**: 使用 Docker Runtime (推荐)
2. **如果没有 Docker**: 
   - 使用 Local Runtime 生成代码修复
   - 说明无法运行测试的原因
   - 展示代码生成能力

**对于生产环境**:
- 必须使用 Docker 或 Remote Runtime
- 确保结果完整和可靠

---

**更新时间**: 2025-11-22

