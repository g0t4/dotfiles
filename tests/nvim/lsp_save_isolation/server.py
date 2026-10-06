"""Small stdio LSP server that records notifications for the Neovim repro."""

import json
import sys


name, log_path = sys.argv[1:3]


def send(message):
    body = json.dumps(message).encode()
    sys.stdout.buffer.write(f"Content-Length: {len(body)}\r\n\r\n".encode() + body)
    sys.stdout.buffer.flush()


while True:
    headers = {}
    while line := sys.stdin.buffer.readline():
        if line == b"\r\n":
            break
        key, value = line.decode().split(":", 1)
        headers[key.lower()] = value.strip()
    if not headers:
        break

    message = json.loads(sys.stdin.buffer.read(int(headers["content-length"])))
    method = message.get("method")
    if method in ("textDocument/didOpen", "textDocument/didSave"):
        with open(log_path, "a") as log:
            log.write(json.dumps({"server": name, "method": method,
                                  "uri": message["params"]["textDocument"]["uri"]}) + "\n")
    if method == "initialize":
        send({"jsonrpc": "2.0", "id": message["id"], "result": {"capabilities": {
            "textDocumentSync": {"openClose": True, "change": 2, "save": True}
        }}})
    elif method == "shutdown":
        send({"jsonrpc": "2.0", "id": message["id"], "result": None})
