import iterm2
from common import *
from logs import *
import time

# so by my math, uv run also adds ~200ms before this point b/c uv run end to end with the below is ~500ms
# start time
start_time = time.time()


async def wes_cmd_n_override(connection: iterm2.Connection):
    print("override started after", (time.time() - start_time) * 1000, "ms") # 200ms by this point!

    prior_window = await get_current_window(connection) # 4ms
    if prior_window is None:
        print("no prior window, opening standard window with default profile")
        await iterm2.Window.async_create(connection)
        return
    print("prior_window after", (time.time() - start_time) * 1000, "ms") # 204ms (so very fast)

    # print("wes new window")
    window = await iterm2.Window.async_create(connection) # 127ms (wow, kinda slow)

    print("window after", (time.time() - start_time) * 1000, "ms") # 331ms

    # window = await iterm2.Window.async_create(connection, profile_customizations=new_profile)
    # TODO detect if SSH'd and if so => re-establish that in new window
    # TODO clone current session


iterm2.run_until_complete(wes_cmd_n_override) # starting alone takes 190ms!
