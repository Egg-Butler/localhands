# OpenHands本地模型对接指南

## 概述
本文档详细说明如何将OpenHands与本地模型对接，用于SWE-Bench评测。

## 方案选择

### 方案1: 使用Ollama (推荐)

#### 优点
- 安装简单，开箱即用
- 支持多种开源模型
- 自动模型管理和优化
- 内存使用优化

#### 安装步骤

1. **安装Ollama**
```bash
# macOS/Linux
curl -fsSL https://ollama.com/install.sh | sh

# macOS也可以使用Homebrew
brew install ollama
```

2. **启动Ollama服务**
```bash
# 启动Ollama服务
ollama serve

# 或者在macOS上，Ollama Desktop会自动运行服务
```

3. **下载推荐的代码模型**
```bash
# Qwen2.5-Coder 14B (推荐 - 性能和质量平衡)
ollama pull qwen2.5-coder:14b

# 或者更大的模型以获得更好的性能
ollama pull qwen2.5-coder:32b

# 其他可选模型
ollama pull codellama:13b
ollama pull deepseek-coder:6.7b
ollama pull starcoder2:15b
```

4. **验证安装**
```bash
# 测试模型
ollama run qwen2.5-coder:14b "Write a Python function to calculate fibonacci numbers"

# 检查已安装的模型
ollama list
```

5. **配置OpenHands**
配置文件已在`config.toml`中设置好，使用以下配置：
```toml
[llm.eval_local_model]
model = "ollama/qwen2.5-coder:14b"
base_url = "http://localhost:11434"
api_key = "ollama"
temperature = 0.0
```

### 方案2: 使用vLLM (适合GPU服务器)

#### 优点
- 高吞吐量
- 批处理推理优化
- 支持tensor并行

#### 安装步骤

1. **安装vLLM**
```bash
pip install vllm
```

2. **启动vLLM服务器**
```bash
# 使用Qwen2.5-Coder-14B-Instruct作为例子
python -m vllm.entrypoints.openai.api_server \
    --model Qwen/Qwen2.5-Coder-14B-Instruct \
    --host 0.0.0.0 \
    --port 8000 \
    --dtype auto \
    --max-model-len 32768
```

3. **配置OpenHands**
```toml
[llm.eval_local_model]
model = "Qwen/Qwen2.5-Coder-14B-Instruct"
base_url = "http://localhost:8000/v1"
api_key = "EMPTY"
temperature = 0.0
```

### 方案3: 使用LM Studio (GUI方式)

#### 优点
- 图形界面操作
- 简单易用
- 适合非技术用户

#### 安装步骤

1. **下载并安装LM Studio**
   访问 https://lmstudio.ai/ 下载适合你系统的版本

2. **在LM Studio中下载模型**
   - 打开LM Studio
   - 搜索 "Qwen2.5-Coder"
   - 下载14B或32B版本

3. **启动本地服务器**
   - 在LM Studio中点击"Local Server"标签
   - 加载下载的模型
   - 启动服务器 (默认端口1234)

4. **配置OpenHands**
```toml
[llm.eval_local_model]
model = "local-model"
base_url = "http://localhost:1234/v1"
api_key = "lm-studio"
```

## 推荐模型

### 用于SWE-Bench评测的最佳模型

1. **Qwen2.5-Coder-14B-Instruct** (强烈推荐)
   - 专门为代码任务训练
   - 支持92种编程语言
   - 上下文长度：32K tokens
   - 在代码生成和修复任务上表现优异

2. **Qwen2.5-Coder-32B-Instruct** (最佳性能)
   - 更强的推理能力
   - 更好的长上下文理解
   - 需要更多GPU内存 (约20GB)

3. **DeepSeek-Coder-V2-Instruct-16B**
   - 在代码理解任务上表现出色
   - 良好的指令遵循能力

4. **CodeLlama-34B-Instruct**
   - Meta开发的代码专用模型
   - 稳定可靠

## 性能优化建议

### 1. 硬件要求
- **最低配置**: 16GB RAM, CPU
- **推荐配置**: 32GB RAM, NVIDIA GPU (8GB+ VRAM)
- **最佳配置**: 64GB RAM, NVIDIA GPU (24GB+ VRAM)

### 2. 模型选择策略
```bash
# 根据可用资源选择模型大小
# 8GB VRAM -> qwen2.5-coder:7b
# 16GB VRAM -> qwen2.5-coder:14b
# 24GB+ VRAM -> qwen2.5-coder:32b
```

### 3. Ollama优化参数
```bash
# 设置GPU层数 (加速推理)
OLLAMA_NUM_GPU=35 ollama serve

# 设置上下文长度
OLLAMA_MAX_CONTEXT=32768 ollama serve

# 设置并发请求数
OLLAMA_NUM_PARALLEL=2 ollama serve
```

### 4. 提示词优化
- 使用清晰的指令
- 提供足够的上下文
- 使用示例 (few-shot learning)

## 验证对接

运行以下Python脚本验证模型对接：

```python
import requests
import json

# 测试Ollama连接
def test_ollama():
    url = "http://localhost:11434/api/generate"
    data = {
        "model": "qwen2.5-coder:14b",
        "prompt": "Write a Python function to reverse a string",
        "stream": False
    }
    response = requests.post(url, json=data)
    if response.status_code == 200:
        print("✅ Ollama连接成功!")
        print(f"响应: {response.json()['response'][:100]}...")
    else:
        print(f"❌ Ollama连接失败: {response.status_code}")

# 测试OpenAI兼容API
def test_openai_compatible():
    url = "http://localhost:8000/v1/chat/completions"
    data = {
        "model": "Qwen/Qwen2.5-Coder-14B-Instruct",
        "messages": [
            {"role": "user", "content": "Write a Python function to reverse a string"}
        ]
    }
    response = requests.post(url, json=data)
    if response.status_code == 200:
        print("✅ vLLM连接成功!")
        print(f"响应: {response.json()['choices'][0]['message']['content'][:100]}...")
    else:
        print(f"❌ vLLM连接失败: {response.status_code}")

if __name__ == "__main__":
    print("测试本地模型连接...")
    test_ollama()
    # test_openai_compatible()  # 如果使用vLLM，取消注释此行
```

## 故障排除

### 问题1: Ollama服务无法启动
```bash
# 检查端口是否被占用
lsof -i :11434

# 杀死占用进程
kill -9 <PID>

# 重启Ollama
ollama serve
```

### 问题2: 内存不足
```bash
# 使用量化模型减少内存使用
ollama pull qwen2.5-coder:7b-q4_0

# 或调整Ollama内存限制
OLLAMA_MAX_LOADED_MODELS=1 ollama serve
```

### 问题3: 推理速度慢
- 确保使用GPU (如果可用)
- 减小max_tokens
- 使用更小的模型
- 启用prompt caching

## 下一步

配置完成后，继续进行SWE-Bench评测：
1. 查看 `swe_benchmark_setup.md` 了解评测配置
2. 运行 `optimization_strategies.md` 中的优化方案
3. 执行评测并生成报告

