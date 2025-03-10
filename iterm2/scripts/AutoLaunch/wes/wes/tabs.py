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


async def wes_cmd_t_override(connection):
    prior_window = await get_current_window_throw_if_none(connection)
    session = await get_session_throw_if_none(connection)
    current_profile = await session.async_get_profile()
    new_profile = current_profile.local_write_only_copy

    # TODO detect if SSH'd and if so then re-establish that in new tab instead of shell

    # pass command async_create_tab OR new_profile.set_command?
    tab = await prior_window.async_create_tab(profile_customizations=new_profile)
