import iterm2


async def get_session(connection: iterm2.Connection):

    # TODO is there a simpler way already built into the API?
    app = await iterm2.async_get_app(connection)
    window = app.current_terminal_window
    if window is None:
        print("No current terminal window")
        return
    return window.current_tab.current_session
