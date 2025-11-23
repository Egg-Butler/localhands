#!/bin/bash
# 本地部署 openhands-lm-7b-v0.1 的完整脚本

set -e

echo "========================================"
echo "本地部署 openhands-lm-7b-v0.1"
echo "========================================"
echo ""

# 设置代理
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7890

MODEL_NAME="all-hands/openhands-lm-7b-v0.1"
PORT=8000

echo "模型: $MODEL_NAME"
echo "端口: $PORT"
echo ""

# 检查是否已安装 vLLM
if ! python3 -c "import vllm" 2>/dev/null; then
    echo "❌ vLLM 未安装"
    echo ""
    echo "正在安装 vLLM..."
    echo "注意: 这可能需要几分钟时间"
    echo ""
    
    # 检查是否有 GPU
    if python3 -c "import torch; print('CUDA可用:', torch.cuda.is_available())" 2>/dev/null; then
        echo "检测到 PyTorch，检查 CUDA..."
        CUDA_AVAILABLE=$(python3 -c "import torch; print(torch.cuda.is_available())" 2>/dev/null || echo "False")
        if [ "$CUDA_AVAILABLE" = "True" ]; then
            echo "✅ 检测到 CUDA，安装 GPU 版本的 vLLM"
            pip install vllm
        else
            echo "⚠️  未检测到 CUDA，安装 CPU 版本的 vLLM (性能较慢)"
            pip install vllm --extra-index-url https://download.pytorch.org/whl/cpu
        fi
    else
        echo "⚠️  未检测到 PyTorch，先安装 PyTorch..."
        pip install torch
        echo "安装 vLLM..."
        pip install vllm
    fi
    
    echo ""
    echo "✅ vLLM 安装完成"
else
    echo "✅ vLLM 已安装"
fi

echo ""
echo "========================================"
echo "启动 vLLM 服务器"
echo "========================================"
echo ""
echo "正在启动 vLLM 服务器..."
echo "模型: $MODEL_NAME"
echo "端口: $PORT"
echo ""
echo "注意:"
echo "  - 首次运行会下载模型，可能需要较长时间"
echo "  - 模型大小约 14GB"
echo "  - 需要足够的 GPU 内存 (推荐 16GB+)"
echo "  - 如果没有 GPU，可以使用 CPU 模式 (非常慢)"
echo ""

# 检查端口是否被占用
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  端口 $PORT 已被占用"
    echo "   请先停止占用该端口的进程，或修改脚本中的 PORT 变量"
    exit 1
fi

# 启动 vLLM 服务器
echo "启动命令:"
echo "python3 -m vllm.entrypoints.openai.api_server \\"
echo "    --model $MODEL_NAME \\"
echo "    --host 0.0.0.0 \\"
echo "    --port $PORT \\"
echo "    --tensor-parallel-size 1"
echo ""

read -p "是否现在启动服务器? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "正在启动..."
    python3 -m vllm.entrypoints.openai.api_server \
        --model "$MODEL_NAME" \
        --host 0.0.0.0 \
        --port "$PORT" \
        --tensor-parallel-size 1
else
    echo "已取消。您可以稍后手动运行上述命令。"
fi

