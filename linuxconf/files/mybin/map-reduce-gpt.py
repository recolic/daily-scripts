#!/usr/bin/python3 -u
import sys, os, json, tempfile, time
from concurrent.futures import ThreadPoolExecutor, as_completed
import lib.recogpt as recogpt

impl = recogpt.impl_load("gpt5")
COST_1M = 0.25

def run_gpt(system_text, user_text):
    chat_prompt = recogpt.prompt_system(system_text) + recogpt.prompt_user(user_text)
    while True: # Retry loop
        try:
            return recogpt.complete(impl, chat_prompt)
        except Exception as e:
            print(f"sleep 30s before retry... ({e})")
            time.sleep(30)

# ===== CONSTANTS =====
TXT_CHUNK_SIZE = 100000 # Bytes in every MAP chunk. Max ~400000 for GPT-5
TMPDIR = "/tmp/gpt-map-reduce.stat"
MAP_THREADS = 12

# ===== Main entry =====
if len(sys.argv) != 4:
    print(f"Usage: {sys.argv[0]} 'MAP_PROMPT' 'REDUCE_PROMPT' huge-input.txt")
    sys.exit(1)

map_prompt, reduce_prompt, hugefile = sys.argv[1:]
with open(hugefile) as f:
    bigtext = f.read()

chunks = [bigtext[i:i+TXT_CHUNK_SIZE] for i in range(0, len(bigtext), TXT_CHUNK_SIZE)]
print(f">> Total chunks: {len(chunks)}, threads {MAP_THREADS}. Estimated input cost: {COST_1M*len(chunks)/40} USD ({deployment})")

# MAP phase
def process_chunk(idx, chunk):
    fname = f"{TMPDIR}/{os.path.basename(hugefile)}_res.{idx}_{len(chunks)}"
    os.makedirs(os.path.dirname(fname), exist_ok=True)
    if os.path.exists(fname):
        return idx, fname, "exists"
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
    return idx, fname, "done"

# MAP: Thread pool
map_files = []
with ThreadPoolExecutor(max_workers=MAP_THREADS) as executor:
    futures = [executor.submit(process_chunk, idx, chunk)
               for idx, chunk in enumerate(chunks, 1)]
    for future in as_completed(futures):
        idx, fname, status = future.result()
        print(f"[{idx}/{len(chunks)}] {status}")
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
print("")
print(f"++ Cleanup cache dir: rm -rf {TMPDIR}")
