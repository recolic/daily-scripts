# GPT-5, tested by recolic
# Used to publish offline MSD handbook: https://github.com/SunsetMkt/MSD-Manual-Portable
import http.server
import socketserver
import zipfile
from urllib.parse import unquote

ZIP_PATH = "site.zip"
INDEX_FILE = "index.html"
PORT = 8001

zip_file = zipfile.ZipFile(ZIP_PATH, 'r')

class ZipHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # Decode, strip query, and normalize
        path = unquote(self.path).split('?', 1)[0].lstrip('/')
        if not path:
            path = INDEX_FILE
        try:
            with zip_file.open(path) as f:
                data = f.read()
        except KeyError:
            self.send_error(404)
            return

        ctype = self.guess_type(path)
        self.send_response(200)
        self.send_header("Content-type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

with socketserver.TCPServer(("", PORT), ZipHandler) as httpd:
    print(f"Serving {ZIP_PATH} on port {PORT}...")
    httpd.serve_forever()


