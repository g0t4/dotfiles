import iterm2

from logs import log


# avoid none soup 4 levels deep in consumer code... feels like a better way to do this (later)
# for now just log why something is missing, if it is missing, otherwise return the level I want
async def get_current_window(connection: iterm2.Connection):
    app = await iterm2.async_get_app(connection)
    if app is None:
        log("No current app")
        return
    window = app.current_window
    if window is None:
        log("No current terminal window")
    return window


async def get_current_tab(connection: iterm2.Connection):
    window = await get_current_window(connection)
    if window is None:
        return
    tab = window.current_tab
    if tab is None:
        log("No current tab")
    return tab


async def get_session(connection: iterm2.Connection):
    app = await iterm2.async_get_app(connection)
    if app is None:
        log("No current app")
        return
    window = app.current_window
    if window is None:
        log("No current terminal window")
        return
    tab = window.current_tab
    if tab is None:
        log("No current tab")
        return
    session = tab.current_session
    if session is None:
        log("No current session")
        return
    return session
