import iterm2
from common import get_session

async def on_f9(connection: iterm2.Connection):
    # this started out with how I use F9 to quit nvim
    #   might be nice to F9 nvim and F9 again to close iterm pane (not all of iterm though)
    #   yes, F9 quits nvim but it only quits the instance in the current pane (thus F9 to close pane)

    # TODO use optional return type to chain next operations w/o needing to check for None (see connection.current_window for alternate API)
    session = await get_session(connection)
    if session is None:
        print("No current session")
        return

    jobName = await session.async_get_variable("jobName")  # see inspector for vars
    if jobName is "nvim":
        # already handled by nvim
        return
    if jobName in ["fish", "bash", "zsh"]:
        # shell command line must be empty to quit
        await session.async_send_text("\x03")  # ctrl+c (clear)
        await session.async_send_text("\x04")  # ctrl+d (exit)
        return
    # TODO others?
