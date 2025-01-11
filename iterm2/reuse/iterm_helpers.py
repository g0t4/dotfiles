import iterm2

from .logs import log


# avoid none soup 4 levels deep in consumer code... feels like a better way to do this (later)
# for now just log why something is missing, if it is missing, otherwise return the level I want
async def get_current_window(connection: iterm2.Connection):
    app = await iterm2.async_get_app(connection)
    if app is None:
        # LOG MESSAGES to help troubleshoot when None is returned...
        # - I use this code in many places, so do a good job logging details here
        # - big reason to have this file is to not have to log all this in consumer code
        log(f"No app from iterm2.async_get_app, got '{app}'")
        return
    current_window = app.current_window
    if current_window is None:
        log(f"No window from app.current_window, got '{current_window}'")
    return current_window


async def get_current_tab(connection: iterm2.Connection):
    current_window = await get_current_window(connection)
    if current_window is None:
        log(f"No window from get_current_window, got '{current_window}'")
        return
    current_tab = current_window.current_tab
    if current_tab is None:
        log(f"No tab from window.current_tab, got '{current_tab}'")
    return current_tab


async def get_current_session(connection: iterm2.Connection):
    current_tab = await get_current_tab(connection)
    if current_tab is None:
        # it is fine to dup log messages here too... functions as a mini stack trace
        log(f"No tab from get_current_tab, got '{current_tab}'")
        return
    current_session = current_tab.current_session
    if current_session is None:
        log(f"No session from tab.current_session, got '{current_session}'")
        return
    return current_session


async def bring_iterm_to_front(connection: iterm2.Connection):
    app = await iterm2.async_get_app(connection)
    if app is None:
        log(f"Cannot bring iTerm to front... No app from iterm2.async_get_app, got '{app}'")
        return
    await app.async_activate()
