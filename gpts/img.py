#!/usr/bin/python3
import tempfile, json
from openai import AzureOpenAI
def rsec(k): import subprocess; return subprocess.run(['rsec', k], check=True, capture_output=True, text=True).stdout.strip()

# Azure/OpenAI parameters
# endpoint         = rsec("Az_OpenAI_API")
# deployment       = "gpt-4.1"
# subscription_key = rsec("Az_OpenAI_KEY")
endpoint         = rsec("Az_OpenAI_API5")
deployment       = "gpt-5-chat"
subscription_key = rsec("Az_OpenAI_KEY5")

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

import os
import base64
from io import BytesIO
from PIL import Image
def encode_image_to_data_uri(image_path, max_size_mb=1):
    max_bytes = max_size_mb * 1024 * 1024

    # Check image file size
    file_size = os.path.getsize(image_path)

    if file_size <= max_bytes:
        with open(image_path, "rb") as f:
            encoded = base64.b64encode(f.read()).decode("utf-8")
        return f"data:image/jpeg;base64,{encoded}"
    else:
        # Compress until under max_bytes
        img = Image.open(image_path).convert("RGB")
        quality = 95
        while True:
            buffer = BytesIO()
            img.save(buffer, format="JPEG", quality=quality, optimize=True)
            size = buffer.tell()
            if size <= max_bytes or quality <= 20:
                print("DEBUG: compressed img bytes=", size)
                encoded = base64.b64encode(buffer.getvalue()).decode("utf-8")
                return f"data:image/jpeg;base64,{encoded}"
            quality -= 5



while True:
    user_input, img_path = sys.argv
    # Append as a user message to chat history
    chat_prompt.append({
        "role": "user",
        "content": [
            {
                "type": "text",
                "text": user_input
            },
            {
                "type": "image_url",
                "image_url": {
                    "url": img_path
                }
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

        print(assistant_text)
        break ## no retry on success
    except Exception as e:
        print(f"Error: {e}")
