import asyncio
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
    server.setblocking(False)
    # TODO I NEED TO LEARN MORE about the non-blocking sockets in lua...
    #   AND the event loop IMPL... just so I can wrap my head around it
    #   AND make sure I don't have any issues (esp issues with race conditions)

    while True:
        log("waiting for connection")
        # conn, _ = server.accept()
        conn, _ = await asyncio.get_running_loop().sock_accept(server)
        conn.setblocking(False)

        # message = conn.recv(1024).decode()
        data = await asyncio.get_running_loop().sock_recv(conn, 1024)
        message = data.decode().strip()
        log(f"message: {message}")

        # TODO add try catch to handle errors so I don't crash my daemon :)
        #   BUT, wait for another failure to happen first so I am adding the right error handling
        await on_nvim_quit_save_window_state(connection, message)
        conn.close()

    server.close()
