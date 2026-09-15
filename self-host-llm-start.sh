#!/bin/bash
# self-host qwen3.8-27b-uncensored on RTX 5060Ti 16GB
api_mode=1
vision=1

[ -d cuda-12.8 ] || ! echo "Plz install: 'https://github.com/ai-dock/llama.cpp-cuda/releases/download/b10423/llama.cpp-b10423-cuda-12.8-amd64.tar.gz'" || exit 1
[ -f Qwen3.8-27B-Uncensored-IQ4_XS.gguf ] && [ -f mmproj-Qwen3.8-27B-Uncensored-f16.gguf ] || ! echo "Get model at huggingface.co/orcarouter/Qwen3.8-27B-Uncensored-GGUF" || exit 1

cd cuda-12.8
args_api=(./llama-server --parallel 1 --host 0.0.0.0 --port 8080) #--log-prompts-dir ../llama-prompt-debug -lv 4
args_cli=(./llama-cli --multiline-input)
args_com=(-m ../Qwen3.8-27B-Uncensored-IQ4_XS.gguf -c 74000 -b 512 -ub 128 -ngl all -fa on -ctk q5_1 -ctv q5_1
    --jinja --reasoning on --temp 1 --top-p 0.95 --top-k 20 --min-p 0 --presence-penalty 0 --repeat-penalty 1)
args_img=(--mmproj ../mmproj-Qwen3.8-27B-Uncensored-f16.gguf --no-mmproj-offload)

[ "$api_mode" = 1 ] && args=("${args_api[@]}") || args=("${args_cli[@]}")
args+=("${args_com[@]}")
[ "$vision" = 1 ] && args+=("${args_img[@]}")
exec "${args[@]}"

