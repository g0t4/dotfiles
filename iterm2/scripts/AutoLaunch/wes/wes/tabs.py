from common import *


async def close_other_tabs(connection):
    current_tab = await get_current_tab_throw_if_none(connection)

    assert current_tab.window is not None
    for tab in current_tab.window.tabs:
        if tab != current_tab:
            await tab.async_close()


async def new_tab_then_close_others(connection):
    window = await get_current_window_throw_if_none(connection)

    # make new tab and close all other tabs in current window
    new_tab = await window.async_create_tab()
    for tab in window.tabs:
        if tab != new_tab:
            await tab.async_close(force=True)


# TODO => fix for my alfred "open in terminal" from finder...  right now if its a remote ssh session on top then it opens to remote

async def wes_new_window(connection: iterm2.Connection, force_local=False):
    prior_window = await get_current_window(connection)
    if prior_window is None:
        log("UNEXPECTED NO PRIOR WINDOW, opening new window")
        # this is not possible AFAIK right now b/c you have to have a window open to invoke keyboard monitor handlers
        await iterm2.Window.async_create(connection)
        return
    session = await get_current_session_throw_if_none(connection)
    current_profile = await session.async_get_profile()
    new_profile = current_profile.local_write_only_copy

    jobName = await session.async_get_variable("jobName")
    path = await session.async_get_variable("path")
    commandLine = await session.async_get_variable("commandLine")
    was_sshed = jobName == "ssh"

    is_ssh = was_sshed and not force_local
    if was_sshed:
        if force_local:
            # for when you are ssh'd and not wanna ssh into new tab/window
            new_profile.set_use_custom_command("No")
        else:
            new_profile.set_command(commandLine)
            new_profile.set_use_custom_command("Yes")

    new_window = await iterm2.Window.async_create(connection, profile_customizations=new_profile)
    if new_window is None:
        raise Exception("UNEXPECTED NO WINDOW CREATED")

    if force_local or not is_ssh:
        # don't cd if local (already handled by cloning the profile)
        return

    new_session = get_current_session_for_window_throw_if_none(new_window)
    new_path = await new_session.async_get_variable("path")
    log(f"new_path: {new_path}, path: {path}")
    if new_path != path:
        await new_session.async_send_text(f"cd {path}; clear\n")
        # clear does same as Cmd+K (clears scrollback, not just screen)


async def wes_new_tab(connection, force_local=False):
    prior_window = await get_current_window_throw_if_none(connection)
    session = await get_current_session_throw_if_none(connection)
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
    was_sshed = jobName == "ssh"

    is_ssh = was_sshed and not force_local
    if was_sshed:
        if force_local:
            # for when you are ssh'd and not wanna ssh into new tab/window
            new_profile.set_use_custom_command("No")
        else:
            new_profile.set_command(commandLine)
            new_profile.set_use_custom_command("Yes")

    # pass command async_create_tab OR new_profile.set_command?
    new_tab = await prior_window.async_create_tab(profile_customizations=new_profile)
    if new_tab is None:
        raise Exception("UNEXPECTED NO TAB CREATED")

    if force_local or not is_ssh:
        return

    new_session = get_current_session_for_current_tab_throw_if_none(new_tab)

    # FYI I don't need to check for SSH, just let it always CD, NBD!
    #   right now variables are not set for what appears to be an unpredictable delay, so for SSSH tabs just CD always...
    #   it is possible I am doing something wrong... that said,
    #     if I introduce delays then variables appear set though it seems they go through an initialization process and I can end up catching them before they are fully set
    #     I cannot wait 1+ second to see what the remote path is
    # new_path = await new_session.async_get_variable("path")
    # print(f"new_path: {new_path}, path: {path}")
    #
    # ALSO, the original path is not always the remote path!
    #     must be a shell integration issue?

    await new_session.async_send_text(f"cd {path}; clear\n")


# *** split panes:
async def wes_split_pane(connection: iterm2.Connection, split_vert: bool = False, force_local=False):
    # *** FYI force_local not passed to this func yet by any wes.py handlers

    session = await get_current_session_throw_if_none(connection)
    current_profile = await session.async_get_profile()
    new_profile = current_profile.local_write_only_copy

    jobName = await session.async_get_variable("jobName")
    path = await session.async_get_variable("path")
    commandLine = await session.async_get_variable("commandLine")
    was_sshed = jobName == "ssh"

    is_ssh = was_sshed and not force_local
    if was_sshed:
        if force_local:
            # for when you are ssh'd and not wanna ssh into new tab/window
            new_profile.set_use_custom_command("No")
        else:
            new_profile.set_command(commandLine)
            new_profile.set_use_custom_command("Yes")

    new_session = await session.async_split_pane(vertical=split_vert, profile_customizations=new_profile)
    if new_session is None:
        raise Exception("UNEXPECTED NO SESSION CREATED")

    if force_local or not is_ssh:
        return

    await new_session.async_send_text(f"cd {path}; clear\n")
