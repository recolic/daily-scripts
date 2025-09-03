#!/usr/bin/python3
import sys, os, json, tempfile
from openai import AzureOpenAI

# ===== CONSTANTS =====
TXT_CHUNK_SIZE = 5000  # characters per map chunk
TMPDIR = "/tmp/gpt-map-reduce.stat"

# ===== from gpt.py =====
def rsec(k):
    import subprocess
    return subprocess.run(['rsec', k], check=True, capture_output=True, text=True).stdout.strip()

# Azure/OpenAI parameters (reuse original)
endpoint         = rsec("Az_OpenAI_API5")
deployment       = "gpt-5-chat"
subscription_key = rsec("Az_OpenAI_KEY5")

client = AzureOpenAI(
    azure_endpoint=endpoint,
    api_key=subscription_key,
    api_version="2025-01-01-preview",
)

def run_gpt(system_text, user_text):
    chat_prompt = [
        {
            "role": "system",
            "content": [
                {"type": "text", "text": system_text}
            ]
        },
        {
            "role": "user",
            "content": [
                {"type": "text", "text": user_text}
            ]
        }
    ]
    completion = client.chat.completions.create(
        model=deployment,
        messages=chat_prompt,
        max_tokens=16000,
        temperature=1,
        top_p=1,
        frequency_penalty=0,
        presence_penalty=0,
        stop=None,
        stream=False
    )
    assistant_text = ""
    if hasattr(completion.choices[0].message, "content"):
        for chunk in completion.choices[0].message.content:
            if isinstance(chunk, dict) and chunk.get("type") == "text":
                assistant_text += chunk.get("text", "")
            elif isinstance(chunk, str):
                assistant_text += chunk
    else:
        assistant_text = str(completion)
    return assistant_text

# ===== Main entry =====
if len(sys.argv) != 4:
    print(f"Usage: {sys.argv[0]} 'MAP_PROMPT' 'REDUCE_PROMPT' huge-input.txt")
    sys.exit(1)

map_prompt, reduce_prompt, hugefile = sys.argv[1:]
with open(hugefile) as f:
    bigtext = f.read()

chunks = [bigtext[i:i+TXT_CHUNK_SIZE] for i in range(0, len(bigtext), TXT_CHUNK_SIZE)]
print(f"Total chunks: {len(chunks)}")

map_files = []

# MAP phase
for idx, chunk in enumerate(chunks, 1):
    fname = f"{TMPDIR}/{hugefile}_res.{idx}"
    if os.path.exists(fname):
        print(f"[{idx}/{len(chunks)}] Exists, skipping.")
        map_files.append(fname)
        continue
    print(f"[{idx}/{len(chunks)}] Processing...")
    sys_prompt_map = (
        "You are in the MAP phase of a map-reduce process.\n"
        "Your task: carefully process the given chunk of text to fulfill the specific MAP_PROMPT below.\n"
        "Produce an output that can later be combined by another AI during the REDUCE phase.\n"
        "MAP_PROMPT:\n" + map_prompt + "\n"
        "REDUCE_PROMPT:\n" + reduce_prompt + "\n"
    )
    result = run_gpt(sys_prompt_map, chunk)
    with open(fname, "w") as f:
        f.write(result)
    map_files.append(fname)

# REDUCE phase
print("Starting REDUCE phase...")
combined_chunks = ""
for fname in map_files:
    combined_chunks += f"=== {os.path.basename(fname)} ===\n"
    combined_chunks += open(fname).read() + "\n\n"

sys_prompt_reduce = (
    "You are in the REDUCE phase of a map-reduce process.\n"
    "Previously, the MAP phase processed separate text chunks according to the MAP_PROMPT.\n"
    "Your task: combine the provided MAP outputs into a single, coherent final output according to the REDUCE_PROMPT.\n"
    "Ensure no important details are lost, resolve duplicates, merge related parts, and make the result as REDUCE_PROMPT requested.\n"
    "MAP_PROMPT:\n" + map_prompt + "\n"
    "REDUCE_PROMPT:\n" + reduce_prompt + "\n"
)

final_output = run_gpt(sys_prompt_reduce, combined_chunks)
print("===== FINAL OUTPUT =====")
print(final_output)

