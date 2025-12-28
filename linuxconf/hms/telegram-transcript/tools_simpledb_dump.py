import simpledb
import sys, os

if os.environ.get("mode") == "http":
    from http.server import BaseHTTPRequestHandler, HTTPServer
    from urllib.parse import urlparse, parse_qs
    port, token = sys.argv[1:]
    
    class SimpleHandler(BaseHTTPRequestHandler):
        def do_GET(self):
            try:
                params = parse_qs(urlparse(self.path).query)
                assert params["token"][0] == token
                resp = simpledb.naive_query(params["expr"][0].split(" "))

                self.send_response(200)
                self.end_headers()
                self.wfile.write(resp.encode())
            except Exception as e:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(f"server err:{e}".encode())
    
    server = HTTPServer(("0.0.0.0", int(port)), SimpleHandler)
    print(f"listen 0.0.0.0:{port}")
    server.serve_forever()
else:
    print(simpledb.naive_query(sys.argv[1:]))
