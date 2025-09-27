#!/usr/bin/python3
import time, os, base64, warnings
from openai import OpenAI, AzureOpenAI
def rsec(k): import subprocess; return subprocess.run(['rsec', k], check=True, capture_output=True, text=True).stdout.strip()

all_impl = {
    # Warning: Azure heavy censorship
    'gpt4.1': lambda: dict(
        model = "gpt-4.1",
        client = AzureOpenAI(
            azure_endpoint=rsec("Az_OpenAI_API"),
            api_key=rsec("Az_OpenAI_KEY"),
            api_version="2025-01-01-preview"
        ),
        extra_args = dict(temperature=1, top_p=1, frequency_penalty=0, presence_penalty=0, stop=None)
    ),
    'gpt5': lambda: dict(
        model = "gpt-5-chat",
        client = AzureOpenAI(
            azure_endpoint=rsec("Az_OpenAI_API5"),
            api_key=rsec("Az_OpenAI_KEY5"),
            api_version="2025-01-01-preview"
        ),
        extra_args = dict(temperature=1, top_p=1, frequency_penalty=0, presence_penalty=0, stop=None)
    ),
    'flash': lambda: dict(
        model = "gemini-2.5-flash",
        client = OpenAI(
            api_key=rsec("Gemini_KEY"),
            base_url="https://generativelanguage.googleapis.com/v1beta/openai/"
        ),
        extra_args = dict()
    ),
    'pro': lambda: dict(
        model = "gemini-2.5-pro",
        client = OpenAI(
            api_key=rsec("Gemini_KEY"),
            base_url="https://generativelanguage.googleapis.com/v1beta/openai/"
        ),
        extra_args = dict()
    )
}

def impl_list():
    return list(all_impl.keys())
def impl_load(name):
    return all_impl[name]()

def cache(content, ext = "md"):
    if not hasattr(cache, "count"): # first call
        cache.count = 1
        cache.prefix = time.strftime('%m%d%H%M%S')
        cache.dir = os.path.expanduser('~/.cache/gpt')
        os.makedirs(cache.dir, exist_ok=True)

    fn = f"{cache.dir}/{cache.prefix}-{cache.count}.{ext}"
    cache.count += 1
    with open(fn, 'w') as f: f.write(content)
    return fn

def _make_b64_image_url(localpath):
    with open(localpath, "rb") as image_file:
        return "data:image/jpeg;base64," + base64.b64encode(image_file.read()).decode('utf-8')
def _make_prompt_ele(role, ctype, content):
    return [ {"role": role, "content": [{"type": ctype, ctype: content}]} ]

def prompt_system(text):
    return _make_prompt_ele("system", "text", text)
def prompt_user(text):
    return _make_prompt_ele("user", "text", text)
def prompt_bot(text):
    return _make_prompt_ele("assistant", "text", text)
def prompt_user_img(url):
    # Example url:
    # http://example.com/hello.jpg
    # https://google.com/meal.png
    # data:image/jpeg;base64,Ug4NDU4LzU5MjgyNV9wcmV2aWV3LmpwZxwA7J3QAAAACVBM...
    # ./path/to/picture.png
    if url.startswith("http"):
        warnings.warn("http/https image url is not supported by Gemini.")
    elif not url.startswith("data:"):
        url = _make_b64_image_url(url)
    return _make_prompt_ele("user", "image_url", {"url": url})
def prompt_init_default():
    return prompt_system("You are an AI assistant that helps people. Sometimes user want short daily conversation, sometimes user need detailed explain, sometimes you must think against user to give useful insights. For complex discussion, your context is limited. So please act like a human and don't unnecessarily say too much.")


def complete(impl, prompt):
    completion = impl['client'].chat.completions.create(
        model=impl['model'],
        messages=prompt,
        max_tokens=16000,
        stream=False,
        **impl['extra_args']
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
    return assistant_text

