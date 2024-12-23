import iterm2


async def on_f9(connection: iterm2.Connection):
    # this started out with how I use F9 to quit nvim
    #   might be nice to F9 nvim and F9 again to close iterm pane (not all of iterm though)
    #   yes, F9 quits nvim but it only quits the instance in the current pane (thus F9 to close pane)

    # TODO make away method to get session
    app = await iterm2.async_get_app(connection)
    window = app.current_terminal_window
    if window is None:
        print("No current terminal window")
        return
    session = window.current_tab.current_session
    if session is None:
        print("No current session")
        return

    jobName = await session.async_get_variable("jobName")  # see inspector for vars
    print(f"jobName: {jobName}")
    if jobName is "nvim":
        # do not handle this
        return
    if jobName in ["fish", "bash", "zsh"]:
        # fish shell won't quit if you have text entered when ctrl+d is pressed
        # must clear the line (otherwise text from F9 shows up asa [20~ and blocks ctrl+d])
        await session.async_send_text("\x03")  # ctrl+c
        await session.async_send_text("\x04")  # ctrl+d
        return
    # TODO others?
