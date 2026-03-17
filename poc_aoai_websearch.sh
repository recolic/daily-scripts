#!/usr/bin/env bash
set -euo pipefail

# POC: Azure OpenAI Responses API + web_search_preview
#
# Expects these message variables to already exist in your shell:
# - system_prompt_text
# - user_msg_1
# - assistent_msg_1
# - user_msg_2
#
# Secrets are fetched from your secret store:
# - Az_OpenAI_API_OAI: base URL like https://.../openai/v1
# - Az_OpenAI_KEY: Azure OpenAI API key

system_prompt_text="${system_prompt_text:-You are a helpful assistant. Use web search when needed and cite sources.}"
user_msg_1="${user_msg_1:-Hi}"
assistent_msg_1="${assistent_msg_1:-Hello! How can I help?}" # keeping your spelling
user_msg_2="${user_msg_2:-What is the latest stable Linux kernel version today? Please browse the web and cite sources.}"

if ! command -v jq >/dev/null 2>&1; then
  echo "Missing dependency: jq" >&2
  exit 1
fi
if ! command -v curl >/dev/null 2>&1; then
  echo "Missing dependency: curl" >&2
  exit 1
fi
if ! command -v rsec >/dev/null 2>&1; then
  echo "Missing dependency: rsec" >&2
  exit 1
fi

AZURE_OPENAI_BASE_URL="${AZURE_OPENAI_BASE_URL:-$(rsec Az_OpenAI_API_OAI)}"
AZURE_OPENAI_API_KEY="${AZURE_OPENAI_API_KEY:-$(rsec Az_OpenAI_KEY)}"
AZURE_OPENAI_MODEL="${AZURE_OPENAI_MODEL:-gpt-5.3-chat}"

endpoint="${AZURE_OPENAI_BASE_URL%/}/responses"

req_json="$(
  jq -n \
    --arg model "$AZURE_OPENAI_MODEL" \
    --arg system "$system_prompt_text" \
    --arg u1 "$user_msg_1" \
    --arg a1 "$assistent_msg_1" \
    --arg u2 "$user_msg_2" \
    '{
      model: $model,
      tools: [{type:"web_search_preview"}],
      input: [
        {role:"system",    content:$system},
        {role:"user",      content:$u1},
        {role:"assistant", content:$a1},
        {role:"user",      content:$u2}
      ]
    }'
)"

resp="$(
  curl -sS -X POST "$endpoint" \
    -H "Content-Type: application/json" \
    -H "api-key: ${AZURE_OPENAI_API_KEY}" \
    -d "$req_json"
)"

# Print the latest assistant message text (assistant msg #2).
echo "$resp" | jq -r '
  .output
  | map(select(.type=="message" and .role=="assistant"))
  | .[-1].content[]
  | select(.type=="output_text")
  | .text
'

