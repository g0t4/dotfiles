import asyncio

import iterm2

from common import *

font_size_stops = [8, 12, 16, 20, 24]

# 8 is tiny
# 12 is small
# 16 is medium
# 20 is large
# 28 is XL
async def smaller_font_wes_stops(connection: iterm2.Connection):
    session = await get_current_session_throw_if_none(connection)
    _, font_size = await get_font_details(session)
    smaller_font_sizes = [f for f in reversed(font_size_stops) if f < font_size]
    smaller_font_size = smaller_font_sizes[0] if len(smaller_font_sizes) > 0 else min(font_size_stops)
    await set_font_size(session, smaller_font_size)

    # await resize_nvim_windows(session)

async def resize_nvim_windows(session: iterm2.Session):

    job_name = await session.async_get_variable("jobName")
    if job_name == "nvim":
        await asyncio.sleep(0.3)
        await session.async_send_text('\x17=')

async def bigger_font_wes_stops(connection: iterm2.Connection):
    session = await get_current_session_throw_if_none(connection)
    _, font_size = await get_font_details(session)
    bigger_font_sizes = [f for f in font_size_stops if f > font_size]
    bigger_font_size = bigger_font_sizes[0] if len(bigger_font_sizes) > 0 else max(font_size_stops)
    await set_font_size(session, bigger_font_size)

    # await resize_nvim_windows(session)
