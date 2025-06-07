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

def append(data_dict):
    append_b64_jsonline('data.db.gi', data_dict)
def dump():
    return read_b64_jsonlines('data.db.gi')

if __name__ == "__main__":
    for d in dump():
        print(d)
