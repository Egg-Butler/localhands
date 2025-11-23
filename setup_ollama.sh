#!/bin/bash

# 设置代理
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7890

echo "================================"
echo "OpenHands 本地模型设置脚本"
echo "================================"
echo ""

# 检查 Ollama 是否已安装
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama 未安装。请先安装 Ollama:"
    echo "   macOS: brew install ollama"
    echo "   或访问: https://ollama.ai"
    exit 1
fi

echo "✅ Ollama 已安装"
echo ""

# 检查 Ollama 服务是否在运行
if ! curl -s http://localhost:11434/api/tags &> /dev/null; then
    echo "⚠️  Ollama 服务未运行，正在启动..."
    echo "   请在新终端窗口运行: ollama serve"
    echo "   然后按 Enter 继续..."
    read -p ""
fi

# 再次检查
if ! curl -s http://localhost:11434/api/tags &> /dev/null; then
    echo "❌ Ollama 服务仍未运行，请手动启动后重试"
    exit 1
fi

echo "✅ Ollama 服务正在运行"
echo ""

# 检查可用模型
echo "📋 检查已安装的模型..."
ollama list

echo ""
echo "📥 准备下载评测所需的模型..."
echo ""

# 基线模型: Qwen2.5-Coder 14B
echo "1. 下载基线模型: qwen2.5-coder:14b (约 8.5GB)"
echo "   这将用于基线评测..."
if ollama list | grep -q "qwen2.5-coder:14b"; then
    echo "   ✅ 模型已存在，跳过下载"
else
    ollama pull qwen2.5-coder:14b
    if [ $? -eq 0 ]; then
        echo "   ✅ 基线模型下载完成"
    else
        echo "   ❌ 基线模型下载失败"
        exit 1
    fi
fi

echo ""

# 优化模型: Qwen2.5-Coder 32B (可选)
echo "2. 下载优化模型: qwen2.5-coder:32b (约 19GB, 可选)"
echo "   这将用于优化版本评测..."
read -p "   是否下载? (y/N): " download_32b

if [[ "$download_32b" =~ ^[Yy]$ ]]; then
    if ollama list | grep -q "qwen2.5-coder:32b"; then
        echo "   ✅ 模型已存在，跳过下载"
    else
        ollama pull qwen2.5-coder:32b
        if [ $? -eq 0 ]; then
            echo "   ✅ 优化模型下载完成"
        else
            echo "   ⚠️  优化模型下载失败，将只使用基线模型"
        fi
    fi
else
    echo "   ⏭️  跳过优化模型下载"
fi

echo ""
echo "🧪 测试模型连接..."
echo ""

# 测试基线模型
echo "测试基线模型 (qwen2.5-coder:14b):"
test_result=$(ollama run qwen2.5-coder:14b "Write a Python function that returns 'Hello World'" --verbose 2>&1 | head -5)
if [ $? -eq 0 ]; then
    echo "✅ 基线模型响应正常"
    echo "$test_result"
else
    echo "❌ 基线模型测试失败"
fi

echo ""
echo "================================"
echo "✅ 本地模型设置完成!"
echo "================================"
echo ""
echo "📌 下一步:"
echo "   1. 确保 Ollama 服务持续运行: ollama serve"
echo "   2. 运行基线评测: ./run_baseline_eval.sh"
echo "   3. 运行优化评测: ./run_optimized_eval.sh"
echo ""

