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

if __name__ == "__main__":
    # # Debug tool. supported op: eq, ne, gt, lt
    # ./dump.py
    # ./dump.py ts gt 1766800000
    # ./dump.py ts gt 1766800000 ts lt 1766811111
    # ./dump.py ts gt 1766800000 is_outgoing eq True sender_id eq 5911111111
    import sys
    
    def is_not_int(x):
        return isinstance(x, str) and not x.lstrip("-").isdigit()
    def assert_(l, op, r):
        #print("DEBUG: ", l, op, r)
        if l is None or r is None: return op == "ne"
        if op == "eq":
            if type(l) is type(r): return l == r
            else: return str(l) == str(r)
        if op == "ne":
            if type(l) is type(r): return l != r
            else: return str(l) != str(r)
        if is_not_int(l) or is_not_int(r): return False
        if op == "gt":
            return int(l) > int(r)
        if op == "lt":
            return int(l) < int(r)

    args = sys.argv[1:]

    try:
        for d in dump():
            ok = True
            for i in range(0, len(args), 3):
                if not assert_(d.get(args[i]), args[i+1], args[i+2]):
                    ok = False
                    break
            if ok:
                print(d)
    except Exception as e:
        print("E " + str(e))

