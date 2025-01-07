import asyncio
import traceback
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
        conn, addr = await loop.sock_accept(server)
        conn.setblocking(False)

        data = await loop.sock_recv(conn, 1024)
        message = data.decode().strip()

        try:
            await on_nvim_quit_save_window_state(connection, message)
        except Exception as e:
            # repro: use wes-dispatcher + finder to open and close a workspace repeatedly (3 to 6 times and it should cause the error with frame's property status not marked "OK"...
            #   possible fix, try again?
            #   is it a race condition wherein the window iss being closed when get frame is called? hard to say...
            stack = traceback.format_exc()
            log(f"save state exception: {stack}")
            # use finder to open via wes-dispatcher... after 3 or 4 closes I will get a failure, last one was:
            # 1/6, 18:53:41.029: save state exception: 2
            # this is the exception before adding this except/log:
            #
            # TODO demo this... cat out this file and use stack trace to jump right to the line of the issue! (iterm matches on the line numbers too, i.e. 374):
            #  PRN keep this around somewhere for testing? (not here once thie bug is fixed)
            #
            # 1/6, 17:38:14.050: Task exception was never retrieved
            # 1/6, 17:38:14.050: future: <Task finished name='Task-8' coro=<semantic_daemon() done, defined at /Users/wes/repos/wes-config/wes-bootstrap/subs/dotfiles/iterm2/scripts/AutoLaunch/wes/wes/semantic_daemon.py:10> exception=GetPropertyException(2)>
            # 1/6, 17:38:14.050: Traceback (most recent call last):
            # 1/6, 17:38:14.050:   File "/Users/wes/repos/wes-config/wes-bootstrap/subs/dotfiles/iterm2/scripts/AutoLaunch/wes/wes/semantic_daemon.py", line 34, in semantic_daemon
            # 1/6, 17:38:14.050:     await on_nvim_quit_save_window_state(connection, message)
            # 1/6, 17:38:14.050:   File "/Users/wes/repos/wes-config/wes-bootstrap/subs/dotfiles/iterm2/scripts/AutoLaunch/wes/wes/semantic_save_window_state.py", line 59, in on_nvim_quit_save_window_state
            # 1/6, 17:38:14.050:     frame = await window.async_get_frame()  # 3ms
            # 1/6, 17:38:14.050:   File "/Users/wes/.config/iterm2/AppSupport/Scripts/AutoLaunch/wes/iterm2env/versions/3.10.4/lib/python3.10/site-packages/iterm2/window.py", line 374, in async_get_frame
            # 1/6, 17:38:14.050:     raise GetPropertyException(response.get_property_response.status)
            # 1/6, 17:38:14.050: iterm2.window.GetPropertyException: 2
            # 1/6, 17:38:31.786:
            #

        # await loop.sock_sendto(conn, b"DONE", addr)
        await loop.sock_sendall(conn, b"DONE")  # TODO sendall or sendto??

        conn.close()

    server.close()
