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


async def wes_cmd_n_override(connection: iterm2.Connection):
    prior_window = await get_current_window(connection)
    if prior_window is None:
        print("UNEXPECTED NO PRIOR WINDOW, opening new window")
        # this is not possible AFAIK right now b/c you have to have a window open to invoke keyboard monitor handlers
        await iterm2.Window.async_create(connection)
        return
    session = await get_session_throw_if_none(connection)
    current_profile = await session.async_get_profile()
    new_profile = current_profile.local_write_only_copy

    # TODO isn't there a way to just copy the current_profile? I do wanna mod it so I don't mind but can I start with a clone instead of new?
    # get current working dir?
    # new_profile.set_custom_directory(current_profile.custom_directory)
    # new_profile.set_initial_directory_mode(iterm2.InitialWorkingDirectory.INITIAL_WORKING_DIRECTORY_CUSTOM)

    # TODO detect if SSH'd and if so => re-establish that in new window
    # TODO for ssh sessions, set ssh command
    # new_profile.set_command(current_profile.command)

    # new_profile._simple_set("Normal Font", current_profile.normal_font)

    window = await iterm2.Window.async_create(connection, profile_customizations=new_profile)


async def wes_cmd_t_override(connection, remote_tab=True):
    prior_window = await get_current_window_throw_if_none(connection)
    session = await get_session_throw_if_none(connection)
    current_profile = await session.async_get_profile()
    new_profile = current_profile.local_write_only_copy

    # TODO detect if SSH'd and if so then re-establish that in new tab instead of shell
    print(" current command: ", current_profile.command)

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

    is_ssh = jobName == "ssh"
    if is_ssh and remote_tab:
        new_profile.set_command(commandLine)
        new_profile.set_use_custom_command("Yes")


    # pass command async_create_tab OR new_profile.set_command?
    tab = await prior_window.async_create_tab(profile_customizations=new_profile)
