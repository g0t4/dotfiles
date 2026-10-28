import iterm2
from common import get_current_session
from logs import log


async def forward_f9(session):
    await session.async_send_text("\x1b[20~")


async def on_f9(connection: iterm2.Connection):
    # this started out with how I use F9 to quit nvim
    #   might be nice to F9 nvim and F9 again to close iterm pane (not all of iterm though)
    #   yes, F9 quits nvim but it only quits the instance in the current pane (thus F9 to close pane)

    # TODO use optional return type to chain next operations w/o needing to check for None (see connection.current_window for alternate API)
    session = await get_current_session(connection)
    if session is None:
        print("No current session")
        return

    deepestJob = await session.async_get_variable("deepestJob")
    jobName = await session.async_get_variable("jobName") # only use this again if issues with new deepestJob
    if deepestJob == "nvim":
        # send to neovim to handle it
        # await session.async_send_text(":qa\r")
        # send F9 to neovim...
        await forward_f9(session)
        return
    is_any_python_version = deepestJob.startswith("python")  # FYI python3.14 (or other version) is why I check for startswith("python")... which is the case with xonsh at least some of the time
    if deepestJob in ["fish", "bash", "zsh", "xonsh", "Python", "lldb", "gdb", "codex"] \
      or is_any_python_version:
        # shell command line must be empty to quit
        await session.async_send_text("\x03")  # ctrl+c (clear)
        await session.async_send_text("\x04")  # ctrl+d (exit)
        return

    if deepestJob in ["ssh"]:
      # assume safe to ctrl+d only (won't work if nested commands on remote... TBD)
        await session.async_send_text("\x04")  # ctrl+d (exit)
        log(f"ssh is not a reliable jobName to decide what to use to F9 remotely {deepestJob=} {jobName=}")
        return


    await forward_f9(session)
    log(f"forwarding F9, current executable not mapped to explicit action: {deepestJob=} {jobName=}")
