import base64,json,urllib.parse,re,sys
def url_get_name(url):
    m=re.search(r"#([^#]+)$",url)
    if m: comm=m.group(1)
    else:
        try: comm=json.loads(base64.b64decode(url.replace("vmess://","")).decode())["ps"]
        except: comm="No_Name"
    comm=urllib.parse.unquote_plus(comm).replace(" ","")
    return comm or "No_Name"
print(url_get_name(sys.argv[1]))

