#!/bin/bash

# 设置代理
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7890

echo "========================================"
echo "修复 Docker buildx 并重试测试"
echo "========================================"
echo ""

# 1. 检查并修复 buildx
echo "1️⃣ 检查 Docker buildx..."
docker buildx ls

echo ""
echo "2️⃣ 使用 desktop-linux 构建器..."
docker buildx use desktop-linux 2>&1

echo ""
echo "3️⃣ 验证构建器状态..."
docker buildx inspect desktop-linux 2>&1 | head -10

echo ""
echo "4️⃣ 测试简单构建..."
echo "   跳过 (直接尝试运行测试)"

echo ""
echo "5️⃣ 尝试手动拉取预构建镜像..."
echo "   尝试拉取 OpenHands Runtime 基础镜像..."
docker pull ghcr.io/openhands/runtime:latest 2>&1 | tail -5 || echo "   拉取失败,将尝试构建"

echo ""
echo "========================================"
echo "准备重新运行测试"
echo "========================================"
echo ""

# 询问是否继续
read -p "是否现在重新运行测试? (y/N): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 重新运行测试..."
    ./quick_test_7b_10min.sh
else
    echo ""
    echo "已准备好,您可以稍后运行: ./quick_test_7b_10min.sh"
fi

