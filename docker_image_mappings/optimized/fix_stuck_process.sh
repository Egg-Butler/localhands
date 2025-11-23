#!/bin/bash

echo "=========================================="
echo "修复卡住的optimized测评进程"
echo "=========================================="
echo ""

# 查找optimized测评进程
PROCESS_ID=$(ps aux | grep "run_infer.py.*optimized" | grep -v grep | awk '{print $2}' | head -1)

if [ -z "$PROCESS_ID" ]; then
    echo "❌ 未找到optimized测评进程"
    exit 1
fi

echo "📋 找到进程ID: $PROCESS_ID"
echo ""

# 检查进程运行时间
ELAPSED=$(ps -p $PROCESS_ID -o etime= | awk '{print $1}')
echo "⏰ 进程已运行时间: $ELAPSED"
echo ""

# 询问用户是否要终止进程
read -p "是否要终止这个卡住的进程? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 取消操作"
    exit 0
fi

echo "🛑 正在终止进程 $PROCESS_ID..."
kill $PROCESS_ID

# 等待进程退出
sleep 2

# 检查进程是否还在运行
if ps -p $PROCESS_ID > /dev/null 2>&1; then
    echo "⚠️  进程仍在运行，强制终止..."
    kill -9 $PROCESS_ID
    sleep 1
fi

# 再次检查
if ps -p $PROCESS_ID > /dev/null 2>&1; then
    echo "❌ 无法终止进程，请手动处理"
    exit 1
else
    echo "✅ 进程已终止"
fi

# 清理Docker容器
echo ""
echo "🧹 清理Docker容器..."
CONTAINER_ID="openhands-runtime-3d5a31be-cdaf-4c-355a51bea854dca"
if docker ps -a | grep -q "$CONTAINER_ID"; then
    docker stop "$CONTAINER_ID" > /dev/null 2>&1
    docker rm "$CONTAINER_ID" > /dev/null 2>&1
    echo "✅ Docker容器已清理"
else
    echo "ℹ️  Docker容器不存在或已清理"
fi

echo ""
echo "=========================================="
echo "✅ 清理完成"
echo "=========================================="
echo ""
echo "📌 下一步操作:"
echo "1. 检查vLLM服务是否正常: curl http://192.168.50.114:8000/v1/models"
echo "2. 重新运行optimized测评: cd docker_image_mappings && ./run_optimized_eval.sh"
echo ""

