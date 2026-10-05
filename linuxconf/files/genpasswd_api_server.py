#!/usr/bin/python3
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote
import subprocess


class Handler(BaseHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        super().end_headers()

    def do_GET(self):
        path = self.path.split("?", 1)[0]
        prefix = "/genpasswd/"
        if not path.startswith(prefix) or path == prefix:
            self.send_error(404)
            return

        try:
            result = subprocess.run(
                ["genpasswd", unquote(path[len(prefix):])],
                stdin=subprocess.DEVNULL,
                capture_output=True,
            )
            status = 200 if result.returncode == 0 else 500
            body = (
                result.stdout.rstrip(b"\r\n")
                if status == 200
                else result.stdout + result.stderr
            )
        except (OSError, ValueError) as exc:
            status, body = 500, str(exc).encode()

        try:
            self.send_response(status)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        except OSError:
            pass  # Client disconnected.


if __name__ == "__main__":
    with ThreadingHTTPServer(("127.0.0.1", 3094), Handler) as server:
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass

