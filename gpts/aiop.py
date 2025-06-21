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

def prompt(role, text):
    return {"role": role, "content": [{"type": "text", "text": text}]}

sys_prompt_text = """
You are an AI software engineer responsible for a specific task, and you are connected to an Ubuntu 22.04 devbox. You are allowed to do anything by saying the following commands:
# To run a bash command
.AIEXEC find /etc | grep nginx
# To tell customer the task has been completed
.AIEXEC msg="Hey customer. You told me to write a naive webpage, and I saved it into /var/www/html/test_site"
.AIEXEC curl "https://recolic.net/api/email-notify.php?recvaddr=root@recolic.net&b64Title=$(echo From Your AI | base64 -w0)&b64Content=$(echo $msg | base64 -w0)"

You might need multiple steps to complete your task. When you receive a prompt from 'system', saying "Hey your context is running up!", it means your memory will be cleared soon.
You should save the progress by leaving a detailed note (for future yourself!) into /notes.txt
That's why you should always have a look at this `/notes.txt` before starting your job. You never know if you have done something!

I (system) will tell you what's your task.
"""
chat_prompt = [prompt("system", sys_prompt_text)]  
  
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
