from common import *


async def close_other_tabs(connection):
    current_tab = await get_current_tab(connection)
    if current_tab is None:
        return

    assert current_tab.window is not None
    for tab in current_tab.window.tabs:
        if tab != current_tab:
            await tab.async_close()


async def new_tab_then_close_others(connection):
    prior_window = await get_current_window(connection)
    if prior_window is None:
        return

    # make new tab and close all other tabs in current window
    new_tab = await prior_window.async_create_tab()
    for tab in prior_window.tabs:
        if tab != new_tab:
            await tab.async_close(force=True)


async def wes_cmd_n_override(connection: iterm2.Connection):
    prior_window = await get_current_window(connection)
    if prior_window is None:
        print("no prior window, opening standard window with default profile")
        await iterm2.Window.async_create(connection)
        return

    # print("wes new window")
    window = await iterm2.Window.async_create(connection)

    # window = await iterm2.Window.async_create(connection, profile_customizations=new_profile)
    # TODO detect if SSH'd and if so => re-establish that in new window
    # TODO clone current session


async def wes_cmd_t_override(connection):
    print("wes new tab")
    return
    prior_window = await get_current_window(connection)
    if prior_window is None:
        return

    # make new tab and close all other tabs in current window
    new_tab = await prior_window.async_create_tab()
    for tab in prior_window.tabs:
        if tab != new_tab:
            await tab.async_close(force=True)
