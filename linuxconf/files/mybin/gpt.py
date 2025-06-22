#!/usr/bin/python3
import os  
import tempfile  
from openai import AzureOpenAI  
def rsec(k): import subprocess; return subprocess.run(['rsec', k], check=True, capture_output=True, text=True).stdout.strip()
  
# Azure/OpenAI parameters  
endpoint = os.getenv("ENDPOINT_URL", rsec("Az_OpenAI_API"))  
deployment = os.getenv("DEPLOYMENT_NAME", "gpt-4.1")  
subscription_key = os.getenv("AZURE_OPENAI_API_KEY", rsec("Az_OpenAI_KEY"))  
  
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
  
def get_multiline_input():  
    print(">> You >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>") 
    text = ""
    mlmode = False
    while True:  
        line = input()  
        if line == "..":
            mlmode = not mlmode
        elif mlmode:
            text += line + '\n'
        elif line.startswith(".f "):
            text += open(line[3:].strip()).read() + '\n'
        elif line == "":
            break
        else:
            text += line + '\n'
    print("<< Bot <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<") 
    # Reconstruct user input with newlines (including internal newlines)  
    return text
  
# Create the tempdir only once, on first use
_tempdir = None
_counter = 1
def save_to_tempfile(content):
    global _tempdir, _counter
    if _tempdir is None:
        _tempdir = tempfile.mkdtemp(prefix="gpt-", dir="/tmp")
    fn = f"{_tempdir}/{_counter}.txt"
    _counter += 1
    with open(fn, 'w') as f:
        f.write(content)
    return fn

print("(finish with empty line. Start/End multi-line with ..)")  
print("(import file with '.f /path/to/file.txt')")  
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
