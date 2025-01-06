import socket
import os
from on_nvim_quit import on_nvim_quit_save_window_state
from logs import log

SOCKET_PATH = "/tmp/iterm2_daemon.sock"


async def semantic_daemon(connection):

    if os.path.exists(SOCKET_PATH):
        os.remove(SOCKET_PATH)

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(SOCKET_PATH)
    server.listen()

    while True:
        conn, _ = server.accept()
        message = conn.recv(1024).decode()
        # log(f"message: {message}")
        message = message.strip()
        await on_nvim_quit_save_window_state(connection, message)
        conn.close()

    server.close()
