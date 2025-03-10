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


async def wes_cmd_n_override(connection: iterm2.Connection, remote_tab=True):
    prior_window = await get_current_window(connection)
    if prior_window is None:
        log("UNEXPECTED NO PRIOR WINDOW, opening new window")
        # this is not possible AFAIK right now b/c you have to have a window open to invoke keyboard monitor handlers
        await iterm2.Window.async_create(connection)
        return
    session = await get_session_throw_if_none(connection)
    current_profile = await session.async_get_profile()
    new_profile = current_profile.local_write_only_copy

    jobName = await session.async_get_variable("jobName")
    path = await session.async_get_variable("path")
    commandLine = await session.async_get_variable("commandLine")

    is_ssh = jobName == "ssh" and remote_tab
    if is_ssh:
        new_profile.set_command(commandLine)
        new_profile.set_use_custom_command("Yes")

    new_window = await iterm2.Window.async_create(connection, profile_customizations=new_profile)
    if new_window is None:
        raise Exception("UNEXPECTED NO WINDOW CREATED")

    if not is_ssh:
        return

    new_session = get_current_tab_session_throw_if_none(new_window)
    new_path = await new_session.async_get_variable("path")
    log(f"new_path: {new_path}, path: {path}")
    if new_path != path:
        await new_session.async_send_text(f"cd {path}; clear\n")
        # clear works well over remote, doesn't have scrollback so don't need Cmd+K


async def wes_cmd_t_override(connection, remote_tab=True):
    prior_window = await get_current_window_throw_if_none(connection)
    session = await get_session_throw_if_none(connection)
    current_profile = await session.async_get_profile()
    new_profile = current_profile.local_write_only_copy

    # vars:
    # commandLine - current foreground job
    #    ssh foo@bar
    # jobName - "ssh", "nvim"
    # pid - of root process in the session
    # uname - os info
    #
    # sshIntegrationLevel https://github.com/gnachman/iterm2-website/blob/master/source/_includes/documentation-variables.md#L41
    #    # FYI I cannot get this to set even if I have shell integration local and remote... need to read iterm codebase... it's a bit obscure about how it works (conductors stuff)
    #    https://iterm2.com/documentation-variables.html
    #    0: No ssh integration.
    #    1: Basic ssh integration.
    #    2: Full ssh integration with all features available.
    # FYI iTerm docs: https://github.com/gnachman/iterm2-website
    #
    #
    # shell integration vars:
    #   lastCommand
    #   path (current working dir - on remote, or local if not remote'd)
    #     homeDirectory - this appears to be on the HOST (local always it seems)
    #   username
    #   hostname
    #
    # iterm2/tab/user/window - vars for other objects
    #
    # FYI another good ref for customizing the profile is `nvim.py` => iterm2/semantic-click-handler/nvim.py

    jobName = await session.async_get_variable("jobName")
    path = await session.async_get_variable("path")
    commandLine = await session.async_get_variable("commandLine")

    is_ssh = jobName == "ssh" and remote_tab
    if is_ssh:
        new_profile.set_command(commandLine)
        new_profile.set_use_custom_command("Yes")

    # pass command async_create_tab OR new_profile.set_command?
    new_tab = await prior_window.async_create_tab(profile_customizations=new_profile)
    if new_tab is None:
        raise Exception("UNEXPECTED NO TAB CREATED")

    if not is_ssh:
        return

    new_session = get_current_session_throw_if_none(new_tab)
    new_path = await new_session.async_get_variable("path")

    log(f"new_path: {new_path}, path: {path}")
    log(f"new_jobName: {await new_session.async_get_variable('jobName')}")
    log(f"new_commandLine: {await new_session.async_get_variable('commandLine')}")
    # weird, new_path (path) isn't set yet? but if I open inspector I see it?!

    if new_path != path:
        await new_session.async_send_text(f"cd {path}; clear\n")
        now_path_is = await new_session.async_get_variable("path")

        new_session2 = get_current_session_throw_if_none(new_tab)
        await new_session2.async_send_text(f"cd {path}; clear\n")
        now_path_is2 = await new_session2.async_get_variable("path")
        log(f"now_path_is: {now_path_is}, now_path_is2: {now_path_is2}")
