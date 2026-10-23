"""Explicit dev-only fixture. Never copied into the production image."""

import json
import ssl
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'{"status":"ok"}')

    def do_POST(self):
        self.rfile.read(min(int(self.headers.get("Content-Length", "0")), 32768))
        result = {
            "riskScore": 0,
            "confidence": 0.0,
            "riskLevel": "safe",
            "isScam": False,
            "category": "unknown",
            "summary": "Тестовая заглушка: анализ не выполнялся.",
            "reasons": [],
            "recommendations": ["Не используйте тестовый ответ для оценки риска."],
        }
        body = json.dumps(
            {
                "choices": [
                    {
                        "finish_reason": "stop",
                        "message": {"content": json.dumps(result, ensure_ascii=False)},
                    }
                ]
            }
        ).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    server = ThreadingHTTPServer(("0.0.0.0", 8443), Handler)
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain("/certs/cert.pem", "/certs/key.pem")
    server.socket = context.wrap_socket(server.socket, server_side=True)
    server.serve_forever()
