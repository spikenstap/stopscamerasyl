#!/bin/sh
set -eu
openssl req -x509 -newkey rsa:2048 -nodes -keyout /certs/key.pem -out /certs/cert.pem -days 1 -subj "/CN=mock-llm" -addext "subjectAltName=DNS:mock-llm" >/dev/null 2>&1
chmod 600 /certs/key.pem
chmod 644 /certs/cert.pem
exec python server.py

