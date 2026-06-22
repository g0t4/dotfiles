import asyncio

import iterm2

from common import *
from logs import log
from timing import Timer

font_size_stops = [8, 12, 16, 20, 24]
_running_wes_stops = False

# 8 is tiny
# 12 is small
# 16 is medium
# 20 is large
# 28 is XL
async def smaller_font_wes_stops(connection: iterm2.Connection):
    global _running_wes_stops
    if _running_wes_stops:
        log("still running last _running_wes_stops request, skipping smaller_font_wes_stops dispatch to avoid iterm2 crash bug (assuming it is due to overlapping zoom requests)")
        return

    with Timer("smaller_font_wes_stops"):
        _running_wes_stops = True
        session = await get_current_session_throw_if_none(connection)
        _, font_size = await get_font_details(session)
        smaller_font_sizes = [f for f in reversed(font_size_stops) if f < font_size]
        smaller_font_size = smaller_font_sizes[0] if len(smaller_font_sizes) > 0 else min(font_size_stops)
        await set_font_size(session, smaller_font_size)
        _running_wes_stops = False

    await nvim_equalize_windows(session)

async def nvim_equalize_windows(session: iterm2.Session):
    if await session.async_get_variable("jobName") != "nvim":
        return

    # TODO how about use VimResized event instead of this?
    # ALSO there are times when I split screen and don't mind that the other half of the nvim instance is hidden...
    # i.e. I have vertical split on windows (left/right half) and I split iterm to left half of screen then I get the left half of nvim (left window) entirely and right is missing, which I like actually cuz I can temporarily use right half of screen for smth else w/o closing right window in neovim)
    await asyncio.sleep(0.2)
    await session.async_send_text('\x17=')  # CTRL-W_=

async def bigger_font_wes_stops(connection: iterm2.Connection):
    global _running_wes_stops
    if _running_wes_stops:
        log("still running last _running_wes_stops request, skipping bigger_font_wes_stops dispatch to avoid iterm2 crash bug (assuming it is due to overlapping zoom requests)")
        return

    with Timer("bigger_font_wes_stops"):
        _running_wes_stops = True
        session = await get_current_session_throw_if_none(connection)
        _, font_size = await get_font_details(session)
        bigger_font_sizes = [f for f in font_size_stops if f > font_size]
        bigger_font_size = bigger_font_sizes[0] if len(bigger_font_sizes) > 0 else max(font_size_stops)
        await set_font_size(session, bigger_font_size)
        _running_wes_stops = False

    await nvim_equalize_windows(session)
