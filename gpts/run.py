#!/usr/bin/python3
import os, sys
import base64
import subprocess
from openai import AzureOpenAI

def rsec(v):
    return subprocess.check_output(["rsec", v], text=True).strip()
task_file, input_txt = sys.argv[1], sys.argv[2]
with open(task_file) as f:
    task_txt = f.read()
print(f"Using task {task_file}, input:\n {input_txt}")

endpoint = os.getenv("ENDPOINT_URL", rsec("Az_OpenAI_API"))
deployment = os.getenv("DEPLOYMENT_NAME", "gpt-4.1")
subscription_key = os.getenv("AZURE_OPENAI_API_KEY", rsec("Az_OpenAI_KEY"))

# Initialize Azure OpenAI client with key-based authentication
client = AzureOpenAI(
    azure_endpoint=endpoint,
    api_key=subscription_key,
    api_version="2025-01-01-preview",
)

# IMAGE_PATH = "YOUR_IMAGE_PATH"
# encoded_image = base64.b64encode(open(IMAGE_PATH, 'rb').read()).decode('ascii')
chat_prompt = [
    {
        "role": "system",
        "content": [
            {
                "type": "text",
                "text": task_txt
            }
        ]
    },
    {
        "role": "user",
        "content": [
            {
                "type": "text",
                "text": input_txt
            }
        ]
    }
]

# Include speech result if speech is enabled
messages = chat_prompt

completion = client.chat.completions.create(
    model=deployment,
    messages=messages,
    max_tokens=800,
    temperature=1,
    top_p=1,
    frequency_penalty=0,
    presence_penalty=0,
    stop=None,
    stream=False
)

#print(completion.to_json())
print(completion.choices[0].message.content)

