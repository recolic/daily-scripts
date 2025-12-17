#!/usr/bin/python3
import json, sys, os
import lib.recogpt as recogpt

if len(sys.argv) < 2:
    alias = 'gpt52'
    print("Available config:", recogpt.impl_list())
else:
    alias = sys.argv[1]

impl = recogpt.impl_load(alias)
chat_prompt = recogpt.prompt_init_default()

T_BLUEB = '\033[44m'
T_CLR = '\033[0m'
def get_multiline_input():
    global chat_prompt
    print(T_BLUEB + ">> You >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" + T_CLR) 
    text = ""
    while True:
        try:
            line = input()
        except (Exception, KeyboardInterrupt) as e:
            if len(chat_prompt) > 1:
                fname = recogpt.cache(json.dumps(chat_prompt, indent=2), "json")
                print(f"<< gpt.py << Saved history to {fname}")
            raise
        if line == "..":
            break
        elif line == ".s":
            fname = recogpt.cache(json.dumps(chat_prompt, indent=2), "json")
            print(f"<< gpt.py << Saved history to {fname}")
        elif line.startswith(".l "):
            chat_prompt = json.loads(open(os.path.expanduser(line[3:].strip())).read())
            print("<< gpt.py << Replaced history with external save")
        elif line.startswith(".f "):
            text += open(os.path.expanduser(line[3:].strip())).read() + '\n'
        elif line.startswith(".i "):
            if line[3:].strip().startswith("http") and "gpt" not in impl["model"]:
                print("<< gpt.py << Rejected. HTTP/HTTPS URL is only for OpenAI model")
            else:
                chat_prompt += recogpt.prompt_user_img(line[3:].strip())
        else:
            text += line + '\n'
    print(T_BLUEB + "<< Bot <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" + T_CLR) 
    # Reconstruct user input with newlines (including internal newlines)
    return text


print("..                   (send your message)")
print(".f path/to/file.txt  (import text file)")
print(".i http://com/x.jpg  (attach image url)")
print(".i path/to/pic.png   (attach image file)")
print(".s                   (save this chat)")
print(".l path/to/chat.json (load previous chat)")
print("model:", impl['model'])
while True:
    user_input = get_multiline_input()
    if not user_input.strip():
        continue  # Ignore empty user input
    # Append as a user message to chat history
    chat_prompt += recogpt.prompt_user(user_input)

    try:
        resp = recogpt.complete(impl, chat_prompt)
    except Exception as e:
        print(f"Error: {e}")
        if "The response was filtered due to the prompt triggering Azure OpenAI" in str(e) and "gpt" in alias:
            print("Triggered fucking azure filter. Loading backup model...")
            impl2 = recogpt.impl_load("grok")
            resp = recogpt.complete(impl2, chat_prompt)
        else:
            continue

    if resp.count('\n') > 100:
        print(f"(Response longer than 100 lines. Saved to {recogpt.cache(resp)})")
    else:
        print(resp)

    chat_prompt += recogpt.prompt_bot(resp)

