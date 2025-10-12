#!/usr/bin/python3
import json, sys, os
sys.path.append('/usr/mybin')
import lib.recogpt as recogpt

impl = recogpt.impl_load(sys.argv[1])
print("model:", impl['model'], file=sys.stderr)

chat_prompt = recogpt.prompt_init_default()
chat_prompt += recogpt.prompt_user(sys.argv[2])
print(recogpt.complete(impl, chat_prompt))

