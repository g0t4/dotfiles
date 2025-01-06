import socket
import sys

SOCKET_PATH = "/tmp/iterm2_daemon.sock"

def send_message(message):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.connect(SOCKET_PATH)
        client.sendall(message.encode())

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: client.py <message>")
        sys.exit(1)

    message = sys.argv[1]
    send_message(message)
