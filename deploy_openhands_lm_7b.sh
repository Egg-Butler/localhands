#!/bin/bash
# 部署 openhands-lm-7b-v0.1 模型的脚本

set -e

echo "========================================"
echo "部署 openhands-lm-7b-v0.1 模型"
echo "========================================"
echo ""

# 设置代理
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7890

# 方案1: 使用 vLLM (推荐，需要GPU)
echo "方案1: 使用 vLLM 部署 (需要GPU)"
echo "----------------------------------------"
echo ""
echo "步骤1: 安装 vLLM"
echo "  pip install vllm"
echo ""
echo "步骤2: 启动 vLLM 服务器"
echo "  python -m vllm.entrypoints.openai.api_server \\"
echo "      --model all-hands/openhands-lm-7b-v0.1 \\"
echo "      --host 0.0.0.0 \\"
echo "      --port 8000 \\"
echo "      --tensor-parallel-size 1"
echo ""
echo "步骤3: 在 config.toml 中配置:"
echo "  [llm.eval_local_model_openhands_lm]"
echo "  model = \"all-hands/openhands-lm-7b-v0.1\""
echo "  base_url = \"http://localhost:8000/v1\""
echo "  api_key = \"EMPTY\""
echo ""

# 方案2: 尝试通过 Ollama 使用 (如果支持)
echo "方案2: 尝试通过 Ollama 使用"
echo "----------------------------------------"
echo ""
echo "注意: Ollama 可能不支持直接从 HuggingFace 导入此模型"
echo "但我们可以尝试:"
echo ""

# 检查 Ollama 是否运行
if command -v ollama &> /dev/null; then
    echo "✅ Ollama 已安装"
    
    # 尝试通过 Ollama 导入 (可能需要先转换格式)
    echo ""
    echo "尝试方法1: 直接导入 (可能不支持)"
    echo "  ollama create openhands-lm-7b -f Modelfile"
    echo ""
    echo "尝试方法2: 使用 HuggingFace 导入工具"
    echo "  需要先安装 ollama-huggingface 工具"
    echo ""
else
    echo "❌ Ollama 未安装"
    echo "  安装: brew install ollama (macOS) 或访问 https://ollama.ai"
fi

echo ""
echo "========================================"
echo "推荐方案: 使用 vLLM"
echo "========================================"
echo ""
echo "如果您有 GPU，推荐使用 vLLM 以获得最佳性能。"
echo "如果没有 GPU，可以考虑使用 CPU 版本的 vLLM 或继续使用 qwen2.5-coder:7b"
echo ""

