#!/usr/bin/env python3
# GPT 5.3; Help save huge html caused by inline-base64-jpeg

HOWTO_SAVE_PAGE = """
const h2Text = document.querySelector("h2")?.innerText || "page";
var html = document.documentElement.outerHTML;
var blob = new Blob([html], {type:'text/html'});
var a = document.createElement('a');
a.href = URL.createObjectURL(blob);
a.download = h2Text + ".html";
a.click();
"""


import sys, re, base64, os, time, random

if len(sys.argv) != 2:
    print("usage: ./imgtrim.py input.html")
    print("Help save huge html caused by inline-base64-jpeg")
    print("")
    print("How to save page? " + HOWTO_SAVE_PAGE)
    sys.exit(1)

inp = sys.argv[1]
out = inp + ".replaced.html"
assets = "assets"
os.makedirs(assets, exist_ok=True)

data = open(inp, "r", encoding="utf-8").read()

pattern = re.compile(r'src="data:image/jpeg;base64,([^"]+)"')

counter = random.randint(10000, 99999)

def repl(m):
    global counter
    counter += 1
    b64 = m.group(1)
    img = base64.b64decode(b64)
    name = f"{int(time.time())}_{counter}.jpeg"
    path = os.path.join(assets, name)
    open(path, "wb").write(img)
    return f'src="{path}"'

data = pattern.sub(repl, data)

open(out, "w", encoding="utf-8").write(data)

