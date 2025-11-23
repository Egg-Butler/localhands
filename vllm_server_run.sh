#!/bin/bash
# 使用系统的gcc/g++进行编译（conda的版本较老，不支持nvcc13）
export PATH=/usr/bin:$PATH

MODEL_PATH="Qwen/Qwen3-14B-AWQ" 

HOST="0.0.0.0"
PORT=8000

MAX_MODEL_LEN=32768
GPU_MEMORY_UTIL=0.85
TENSOR_PARALLEL_SIZE=1

python -m vllm.entrypoints.openai.api_server \
    --model "$MODEL_PATH" \
    --host "$HOST" \
    --port "$PORT" \
    --max-model-len "$MAX_MODEL_LEN" \
    --gpu-memory-utilization "$GPU_MEMORY_UTIL" \
    --tensor-parallel-size "$TENSOR_PARALLEL_SIZE" \
    --quantization awq \
    --dtype auto \
    --kv-cache-dtype fp8 \
    --trust-remote-code
