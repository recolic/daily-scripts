#!/usr/bin/python3
import tempfile, json
from openai import AzureOpenAI
def rsec(k): import subprocess; return subprocess.run(['rsec', k], check=True, capture_output=True, text=True).stdout.strip()

# Azure/OpenAI parameters
endpoint         = rsec("Az_OpenAI_API")
deployment       = "gpt-4.1"
subscription_key = rsec("Az_OpenAI_KEY")

client = AzureOpenAI(
    azure_endpoint=endpoint,
    api_key=subscription_key,
    api_version="2025-01-01-preview",
)

chat_prompt = [
    {
        "role": "system",
        "content": [
            {
                "type": "text",
                "text": "You are an AI assistant that helps people. Sometimes user want short daily conversation, sometimes user need detailed explain, sometimes you must think against user to give useful insights. For complex discussion, your context is limited. So please act like a human and don't unnecessarily say too much."
            }
        ]
    }
]

# Create the tempdir only once, on first use
_tempdir = None
_counter = 1
def save_to_tempfile(content, ext = "md"):
    global _tempdir, _counter
    if _tempdir is None:
        _tempdir = tempfile.mkdtemp(prefix="gpt-", dir="/tmp")
    fn = f"{_tempdir}/{_counter}.{ext}"
    _counter += 1
    with open(fn, 'w') as f:
        f.write(content)
    return fn

T_BLUEB = '\033[44m'
T_CLR = '\033[0m'
def get_multiline_input():
    global chat_prompt
    print(T_BLUEB + ">> You >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" + T_CLR) 
    text = ""
    while True:
        line = input()
        if line == "..":
            break
        elif line == ".s":
            fname = save_to_tempfile(json.dumps(chat_prompt, indent=2), "json")
            print(f"<< gpt.py << Saved history to {fname}")
        elif line.startswith(".l "):
            chat_prompt = json.loads(open(line[3:].strip()).read())
            print("<< gpt.py << Replaced history with external save")
        elif line.startswith(".f "):
            text += open(line[3:].strip()).read() + '\n'
        else:
            text += line + '\n'
    print(T_BLUEB + "<< Bot <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" + T_CLR) 
    # Reconstruct user input with newlines (including internal newlines)
    return text


print("..                   (send your message)")
print(".f path/to/file.txt  (import text file)")
print(".s                   (save this chat)")
print(".l path/to/chat.json (load previous chat)")
while True:
    user_input = get_multiline_input()
    if not user_input.strip():
        continue  # Ignore empty user input
    # Append as a user message to chat history
    chat_prompt.append({
        "role": "user",
        "content": [
            {
                "type": "text",
                "text": user_input
            }
        ]
    })

    # Query GPT
    try:
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
        # Extract assistant reply (Azure format: a list, we just join)
        assistant_text = ""
        # Azure's completion structure: choices[0].message.content is a list of dicts with 'type':'text', 'text':...
        # So we gather all text chunks together
        if hasattr(completion.choices[0].message, "content"):
            for chunk in completion.choices[0].message.content:
                if isinstance(chunk, dict) and chunk.get("type") == "text":
                    assistant_text += chunk.get("text", "")
                elif isinstance(chunk, str):
                    assistant_text += chunk
        else:
            # fallback for possible alternative return formats
            assistant_text = str(completion)

        # Print or save
        num_lines = assistant_text.count('\n') + 1
        if num_lines > 100:
            filepath = save_to_tempfile(assistant_text)
            print(f"(Response longer than 100 lines. Saved to {filepath})")
        else:
            print(assistant_text)
        # Add assistant response to chat history
        chat_prompt.append({
            "role": "assistant",
            "content": [
                {
                    "type": "text",
                    "text": assistant_text
                }
            ]
        })
    except Exception as e:
        print(f"Error: {e}")
