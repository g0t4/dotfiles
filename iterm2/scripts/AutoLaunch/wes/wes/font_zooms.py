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

    profile = await session.async_get_profile()
    font = profile.normal_font

    splits = str(font).split(' ')
    font_name = ' '.join(splits[:-1])
    font_size = splits[-1]

    # find font size smaller than current size
    new_font_size = [f for f in reversed(font_size_stops) if int(f) < int(font_size)]
    new_font_size = new_font_size[0] if len(new_font_size) > 0 else min(font_size_stops)
    print(f"change font size from {font_size} to {new_font_size}")
    await profile.async_set_normal_font(font_name + " " + str(new_font_size))

async def bigger_font_wes_stops(connection: iterm2.Connection):

    session = await get_current_session_throw_if_none(connection)

    profile = await session.async_get_profile()
    font = profile.normal_font
    # font == "SauceCodeProNF 12"

    splits = str(font).split(' ')
    font_name = ' '.join(splits[:-1])
    font_size = splits[-1]

    # find font size bigger than current size
    new_font_size = [f for f in font_size_stops if int(f) > int(font_size)]
    new_font_size = new_font_size[0] if len(new_font_size) > 0 else max(font_size_stops)
    print(f"change font size from {font_size} to {new_font_size}")
    await profile.async_set_normal_font(font_name + " " + str(new_font_size))
