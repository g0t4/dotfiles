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

        try:
            await on_nvim_quit_save_window_state(connection, message)
        except Exception as e:
            # TODO reproduce a legit example of this?
            #   MIGHT HAPPEN even in spite of blocking uv.run client call... if window is removed before server can get win position/state... I think I saw that recently...
            #   though honestly not saving one time is NBD... old position will be used and as long as I don't terminate my daemon on that failure, all will be fine
            log(f"save state exception: {e}")
            # use finder to open via wes-dispatcher... after 3 or 4 closes I will get a failure, last one was:
            # 1/6, 18:53:41.029: save state exception: 2
            # this is the exception before adding this except/log:
            #   Task exception was never retrieved
            #   future: <Task finished name='Task-8' coro=<semantic_daemon() done, defined at /Users/wes/repos/wes-config/wes-bootstrap/subs/dotfiles/iterm2/scripts/AutoLaunch/wes/wes/semantic_daemon.py:10> exception=GetPropertyException(2)>
        conn.close()

    server.close()
