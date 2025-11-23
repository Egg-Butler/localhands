#!/usr/bin/env python3
import json
import sys

output_file = "OpenHands/evaluation/evaluation_outputs/outputs/princeton-nlp__SWE-bench-test/CodeActAgent/qwen2.5-coder_7b_maxiter_25/output.jsonl"

with open(output_file, 'r') as f:
    for line in f:
        data = json.loads(line)
        instance_id = data.get('instance_id', 'unknown')
        print(f"实例ID: {instance_id}")
        print("=" * 60)
        
        # 查看instruction
        if 'instruction' in data:
            instruction = data['instruction']
            print(f"\n任务描述:\n{instruction[:300]}...")
        
        # 分析history
        if 'history' in data and isinstance(data['history'], list):
            history = data['history']
            print(f"\n历史记录总数: {len(history)}")
            
            # 统计消息类型
            user_msgs = []
            agent_msgs = []
            for event in history:
                if isinstance(event, dict):
                    source = event.get('source', '')
                    message = event.get('message', '')
                    if source == 'user':
                        user_msgs.append(message)
                    elif source == 'agent':
                        agent_msgs.append(message)
            
            print(f"\n用户消息数: {len(user_msgs)}")
            print(f"Agent消息数: {len(agent_msgs)}")
            
            # 查看Agent的消息，通常包含操作指令
            print(f"\n=== Agent 的操作指令 (前10条) ===")
            for i, msg in enumerate(agent_msgs[:10], 1):
                # Agent消息通常包含代码块或操作指令
                if '```' in msg or 'run' in msg.lower() or 'read' in msg.lower() or 'write' in msg.lower():
                    preview = msg[:300].replace('\n', ' ')
                    print(f"{i}. {preview}...")
        
        break  # 只处理第一个实例
