#!/usr/bin/env python3
"""Servidor local só para desenvolvimento/teste (http://localhost:8765)."""
import os, sys, functools
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler

AQUI = os.path.dirname(os.path.abspath(__file__))
os.chdir(AQUI)

class H(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()

porta = int(sys.argv[1]) if len(sys.argv) > 1 else 8765
print('servindo', AQUI, 'em http://localhost:%d' % porta, flush=True)
ThreadingHTTPServer(('127.0.0.1', porta), functools.partial(H, directory=AQUI)).serve_forever()
