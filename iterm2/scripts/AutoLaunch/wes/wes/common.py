import iterm2
import typing

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

# PRN consider renaming asyncs to async_* ?

# if a consumer needs to work with possibility of None, then use this to at least help log details if its missing and shouldn't be
async def get_current_window(connection: iterm2.Connection) -> typing.Optional[iterm2.Window]:
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

# FYI impetus is to not litter consume code with if None checks... just throw here and provide all the nice details about what is wrong
#   that way consumers can assume happy path (or exception if not, and something else catches that for them too)
async def get_current_window_throw_if_none(connection: iterm2.Connection) -> iterm2.Window:
    app = await iterm2.async_get_app(connection)
    if app is None:
        raise Exception("No app from iterm2.async_get_app (got None)")
    window = app.current_window
    if window is None:
        raise Exception("No window from app.current_window (got None)")
    return window

async def get_current_tab(connection: iterm2.Connection) -> typing.Optional[iterm2.Tab]:
    window = await get_current_window(connection)
    if window is None:
        log("No window from get_current_window (got None)")
        return
    tab = window.current_tab
    if tab is None:
        log("No tab from window.current_tab (got None)")
    return tab

async def get_current_tab_throw_if_none(connection: iterm2.Connection) -> iterm2.Tab:
    window = await get_current_window_throw_if_none(connection)
    tab = window.current_tab
    if tab is None:
        raise Exception("No tab from window.current_tab (got None)")
    return tab

async def get_current_session(connection: iterm2.Connection) -> typing.Optional[iterm2.Session]:
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

async def get_current_session_throw_if_none(connection: iterm2.Connection) -> iterm2.Session:
    tab = await get_current_tab(connection)
    if tab is None:
        raise Exception("No tab from get_current_tab (got None)")
    session = tab.current_session
    if session is None:
        raise Exception("No session from tab.current_session (got None)")
    return session

# *** sync helpers to avoid None check hell ***
def get_current_tab_for_window_throw_if_none(window: iterm2.Window) -> iterm2.Tab:
    tab = window.current_tab
    if tab is None:
        raise Exception("No tab from window.current_tab (got None)")
    return tab

def get_current_session_for_current_tab_throw_if_none(tab: iterm2.Tab) -> iterm2.Session:
    session = tab.current_session
    if session is None:
        raise Exception("No session from tab.current_session (got None)")
    return session

def get_current_session_for_window_throw_if_none(window: iterm2.Window) -> iterm2.Session:
    tab = get_current_tab_for_window_throw_if_none(window)
    session = get_current_session_for_current_tab_throw_if_none(tab)
    return session

# *** misc other helpers
#
async def bring_iterm_to_front(connection: iterm2.Connection):
    app = await iterm2.async_get_app(connection)
    if app is None:
        log(f"Cannot bring iTerm to front... No app from iterm2.async_get_app, got '{app}'")
        return
    await app.async_activate()

# *** font size / name
async def get_font_details(session):
    profile = await session.async_get_profile()
    font = profile.normal_font
    splits = str(font).split(' ')
    font_name = ' '.join(splits[:-1])
    font_size = splits[-1]
    return font_name, int(font_size)

async def set_font_size(session: iterm2.Session, new_size):
    profile = await session.async_get_profile()
    print("set font size", new_size)
    font_name, _ = await get_font_details(session)
    await profile.async_set_normal_font(f"{font_name} {new_size}")
