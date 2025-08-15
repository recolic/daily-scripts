from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import random
import string

PORT = 9999
tasks = {}

def random_id():
    return ''.join(random.choices(string.ascii_uppercase + string.digits + '-', k=20))

class Handler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.end_headers()

    def do_POST(self):
        if self.path.startswith('/api/v1/tasks'):
            length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(length)
            if length == 0 or not body.strip():
                data = {}
            else:
                try:
                    data = json.loads(body)
                except Exception:
                    data = {}
            # Get netdisk user agent from JSON
            req = data.get('req', {})
            ua = (
                req.get('extra', {})
                   .get('header', {})
                   .get('User-Agent', '')
            )
            url = req.get('url')
            if url is not None:
                print(f"aria2c -x 6 --user-agent '{ua}' '{url}'")
            id_ = random_id()
            tasks[id_] = {
                "id": id_,
                "protocol": "http",
                "meta": {"req": req},
                "status": "running",
                "name": ua
            }
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            resp = {"code": 0, "msg": "", "data": id_}
            self.wfile.write(json.dumps(resp).encode())
        else:
            self.send_error(404)

    def do_GET(self):
        if self.path.startswith('/api/v1/tasks'):
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            data = []
            for v in tasks.values():
                data.append({
                    "id": v["id"],
                    "protocol": v["protocol"],
                    "meta": v["meta"],
                    "status": "running",
                    "name": v["name"]
                })
            resp = {"code": 0, "msg": "", "data": data}
            self.wfile.write(json.dumps(resp).encode())
        else:
            self.send_error(404)

    def log_message(self, format, *args):
        return  # silence default logging

if __name__ == '__main__':
    with HTTPServer(('0.0.0.0', PORT), Handler) as httpd:
        print(f'Starting server at http://127.0.0.1:{PORT}')
        httpd.serve_forever()

