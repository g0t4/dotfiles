import iterm2

from logs import log


def print_keystroke(keystroke):
    debug_message = f"key:"
    if keystroke.characters is not None:
        chars = keystroke.characters
        if len(chars) > 0:
            debug_message += f" {chars}"
    for mod in keystroke.modifiers:
        if mod == iterm2.Modifier.COMMAND:
            debug_message += " CMD"
        elif mod == iterm2.Modifier.SHIFT:
            debug_message += " SHIFT"
        elif mod == iterm2.Modifier.CONTROL:
            debug_message += " CTRL"
        elif mod == iterm2.Modifier.OPTION:
            debug_message += " ALT"
        elif mod == iterm2.Modifier.FUNCTION:
            debug_message += " FN"
        elif mod == iterm2.Modifier.NUMPAD:
            debug_message += " NUMPAD"
        else:
            debug_message += f" {mod}"
    if keystroke.keycode is not None:
        key = str(keystroke.keycode)
        # remove leading Keycode.
        if key.startswith("Keycode."):
            key = key[8:]
        debug_message += f" {key}"
    log(debug_message)


# avoid none soup 4 levels deep in consumer code... feels like a better way to do this (later)
# for now just log why something is missing, if it is missing, otherwise return the level I want
async def get_current_window(connection: iterm2.Connection):
    app = await iterm2.async_get_app(connection)
    if app is None:
        # LOG MESSAGES to help troubleshoot when None is returned...
        # - I use this code in many places, so do a good job logging details here
        # - big reason to have this file is to not have to log all this in consumer code
        log("No app from iterm2.async_get_app (got None)")
        return
    window = app.current_window
    if window is None:
        log("No window from app.current_window (got None)")
    return window


async def get_current_tab(connection: iterm2.Connection):
    window = await get_current_window(connection)
    if window is None:
        log("No window from get_current_window (got None)")
        return
    tab = window.current_tab
    if tab is None:
        log("No tab from window.current_tab (got None)")
    return tab


async def get_session(connection: iterm2.Connection):
    tab = await get_current_tab(connection)
    if tab is None:
        # it is fine to dup log messages here too... functions as a mini stack trace
        log("No tab from get_current_tab (got None)")
        return
    session = tab.current_session
    if session is None:
        log("No session from tab.current_session (got None)")
        return
    return session


async def get_session_throw_if_none(connection: iterm2.Connection):
    tab = await get_current_tab(connection)
    if tab is None:
        raise Exception("No tab from get_current_tab (got None)")
    session = tab.current_session
    if session is None:
        raise Exception("No session from tab.current_session (got None)")
    return session


async def get_current_window_throw_if_none(connection: iterm2.Connection):
    app = await iterm2.async_get_app(connection)
    if app is None:
        raise Exception("No app from iterm2.async_get_app (got None)")
    window = app.current_window
    if window is None:
        raise Exception("No window from app.current_window (got None)")
    return window
