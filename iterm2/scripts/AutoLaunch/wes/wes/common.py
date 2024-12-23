import iterm2


async def get_session(connection: iterm2.Connection):
    app = await iterm2.async_get_app(connection)
    if app is None:
        print("No current app")
        return
    window = app.current_window
    if window is None:
        print("No current terminal window")
        return
    tab = window.current_tab
    if tab is None:
        print("No current tab")
        return
    session = tab.current_session
    if session is None:
        print("No current session")
        return
    return session
