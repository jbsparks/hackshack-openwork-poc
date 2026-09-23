#!/usr/bin/env python3
"""Minimal HTTP server: serves tutorial.html at / and lab docs at /docs/"""
import http.server

LABS_DIR = "/root/labs"
PORT = 8080

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=LABS_DIR, **kwargs)

    def do_GET(self):
        if self.path == "/" or self.path == "/index.html":
            self.path = "/tutorial.html"
        elif self.path.startswith("/docs/"):
            self.path = "/" + self.path[6:]
        return super().do_GET()

if __name__ == "__main__":
    print(f"[OK] Tutorial server on port {PORT}")
    server = http.server.HTTPServer(("0.0.0.0", PORT), Handler)
    server.serve_forever()
