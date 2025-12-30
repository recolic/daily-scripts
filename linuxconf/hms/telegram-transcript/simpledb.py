import json
import base64

def append_b64_jsonline(filename, data_dict):
    json_bytes = json.dumps(data_dict, ensure_ascii=False).encode('utf-8')
    b64_line = base64.b64encode(json_bytes).decode('ascii')
    with open(filename, 'a', encoding='utf-8') as f:
        f.write(b64_line + '\n')


def read_b64_jsonlines(filename):  
    with open(filename, 'r', encoding='utf-8') as f:  
        for line in f:  
            line = line.rstrip('\n')  
            try:  
                json_bytes = base64.b64decode(line)  
                yield json.loads(json_bytes.decode('utf-8'))  
            except Exception:  
                continue  # skip malformed/corrupt lines

dbpath = 'data.db.gi'
def append(data_dict):
    append_b64_jsonline(dbpath, data_dict)
def dump():
    return read_b64_jsonlines(dbpath)

def naive_query(args):
    # # Debug tool. supported filter: eq, ne, gt, lt; supported summarize: count, countby, first, last
    # ./dump.py [<filter_l filter_op filter_r>, ...] [summarize_op, [summarize_arg]]
    # ./dump.py
    # ./dump.py ts gt 1766800000
    # ./dump.py ts gt 1766800000 is_outgoing eq True sender_id eq 5911111111
    # ./dump.py ts gt 1766800000 ts lt 1766811111
    # ./dump.py ts gt 1766800000 ts lt 1766811111 count
    # ./dump.py ts gt 1766800000 ts lt 1766811111 countby chat_id
    # ./dump.py ts gt 1766800000 ts lt 1766811111 first 10
    # ./dump.py ts gt 1766800000 ts lt 1766811111 last 10

    def is_not_int(x):
        return isinstance(x, str) and not x.lstrip("-").isdigit()
    def assert_(l, op, r):
        #print("DEBUG: ", l, op, r)
        if l is None or r is None: return op == "ne"
        if op == "eq":
            if type(l) is type(r): return l == r
            else:     return str(l).lower() == str(r).lower()
        if op == "ne":
            if type(l) is type(r): return l != r
            else:     return str(l).lower() != str(r).lower()
        if is_not_int(l) or is_not_int(r): return False
        if op == "gt":
            return int(l) > int(r)
        if op == "lt":
            return int(l) < int(r)

    output_kvs, output_str = dict(), []
    countby, first_idx, last_idx = None, None, None
    if "count" in args:
        countby = ""
        args = args[:args.index("count")]
    if "countby" in args:
        countby = args[args.index("countby") + 1]
        args = args[:args.index("countby")]
    if "first" in args:
        first_idx = int(args[args.index("first") + 1])
        args = args[:args.index("first")]
    if "last" in args:
        last_idx = - int(args[args.index("last") + 1])
        args = args[:args.index("last")]

    tap_output_k = lambda k: output_kvs.__setitem__(k, output_kvs.get(k, 0) + 1)

    try:
        for d in dump():
            ok = True
            for i in range(0, len(args), 3):
                if not assert_(d.get(args[i]), args[i+1], args[i+2]):
                    ok = False
                    break
            if ok: ## output
                if countby is None:
                    output_str.append(json.dumps(d, ensure_ascii=False))
                elif countby == "":
                    tap_output_k("count")
                elif countby in d:
                    tap_output_k(d[countby])
    except Exception as e:
        output_str = "E " + repr(e)

    for k, v in output_kvs.items():
        output_str.append(json.dumps({"countby": k, "count": v}, ensure_ascii=False))
    return "\n".join(output_str[last_idx:None][None:first_idx])


