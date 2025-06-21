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

def pp(role, text):
    print(f"DEBUG: {role} -> {text}")
    return {"role": role, "content": [{"type": "text", "text": text}]}

sys_prompt_text = """
You are an AI software engineer responsible for a specific task, and you are connected to an Ubuntu 22.04 devbox. You are allowed to do anything by saying the following commands:
# To run a bash command
.AIEXEC find /etc | grep nginx
# To tell customer the task has been completed
.AIEXEC msg="Hey customer. You told me to write a naive webpage, and I saved it into /var/www/html/test_site"
.AIEXEC curl "https://recolic.net/api/email-notify.php?recvaddr=root@recolic.net&b64Title=$(echo From Your AI | base64 -w0)&b64Content=$(echo $msg | base64 -w0)"

You should also notify the customer if something prevents you from doing your job.
For example, if you are told to test some virtual machine software, but nested virtualization is not available for your devbox.

You might need multiple steps to complete your task. When you receive a prompt from 'system', saying "Hey your context is running up!", it means your memory will be cleared soon.
Then, you should save the progress by leaving a detailed note (for future yourself!) into /notes.txt
That's why you should always have a look at this `/notes.txt` before starting your job. You never know if you have done something!

I (system) will tell you what's your task.
"""

chat_prompt = [pp("system", sys_prompt_text)]
chat_prompt.append(pp("system", "From customer: To test your ability, your current task is to figure out how to use 'https://recolic.net/paste/apibin.php?ns=test', and put your machine information into that pastebin."))
 
while True:
    input("press enter to send req")
    # Query GPT
    try:
        completion = client.chat.completions.create(
            model=deployment,
            messages=chat_prompt,
            max_tokens=32000,
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

        stdout = ""
        stderr = ""
        for line in assistant_text:
            if line.startswith(".AIEXEC "):
                # TODO: exec ai command
                stdout += "\n"
                stderr += "devbox is unavailable after 5min... please tell your customer something went wrong.\n"

        # Add assistant response to chat history
        chat_prompt.append(pp("AI software engineer", assistant_text)
        chat_prompt.append(pp("devbox.stdout", stdout))
        chat_prompt.append(pp("devbox.stderr", stdout))
        # TODO: when context size is almost being reached..
    except Exception as e:
        print(f"Error: {e}")
