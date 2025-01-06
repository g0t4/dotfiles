import asyncio
import socket
import os
from semantic_save_window_state import on_nvim_quit_save_window_state
from logs import log

SOCKET_PATH = os.path.expanduser("~/.config/wes-iterm2/run/semantic-click-handler.sock")


async def semantic_daemon(connection):

    if not os.path.exists(os.path.dirname(SOCKET_PATH)):
        os.makedirs(os.path.dirname(SOCKET_PATH))

    if os.path.exists(SOCKET_PATH):
        os.remove(SOCKET_PATH)

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(SOCKET_PATH)
    server.listen()
    server.setblocking(False)
    # non-blocking so other tasks can run too (i.e. iterm key monitor)

    while True:
        loop = asyncio.get_running_loop()
        conn, _ = await loop.sock_accept(server)
        conn.setblocking(False)

        data = await loop.sock_recv(conn, 1024)
        message = data.decode().strip()

        # TODO add try catch to handle errors so I don't crash my daemon :)
        #   BUT, wait for another failure to happen first so I am adding the right error handling
        await on_nvim_quit_save_window_state(connection, message)
        conn.close()

    server.close()
