import os
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

async def prepare_new_profile(session: iterm2.Session, force_local: bool) -> tuple[iterm2.LocalWriteOnlyProfile, bool]:
    tab = session.tab
    tab_id = tab.tab_id if tab is not None else "missing tab"
    window = session.window
    window_id = window.window_id if window is not None else "missing window"
    print(f"session_id={session.session_id}, tab_id: {tab_id}, window: {window_id}")

    current_profile = await session.async_get_profile()

    # ** logging of font sizing to see if I can find why src font is sometimes wrong size!
    #    i.e.  parent tiny font, open new tab and reset its font to default big, then new window/tab is wrong usually
    #    so far cannot reproduce this
    #
    # smth weird is happening with font size, sometimes the font size of the current session returns a value for what might be the parent session!?
    src_font_values = current_profile._simple_get("Normal Font")
    src_normal_font = current_profile.normal_font
    print(f"src profile font values:{src_font_values}, normal_font: {src_normal_font}")
    # FYI AFAICT I do not have to set the font (its copied into new profile):
    new_profile = current_profile.local_write_only_copy
    new_font_values = new_profile.values["Normal Font"]
    print(f"new_profile font size: {new_font_values}")

    # print(f"directories:\n  {current_profile.custom_directory},\n  {current_profile.initial_directory_mode},\n  {current_profile.advanced_working_directory_pane_directory}\n  {current_profile.advanced_working_directory_pane_setting}\n  {current_profile.advanced_working_directory_tab_directory}\n  {current_profile.advanced_working_directory_tab_setting}\n  {current_profile.advanced_working_directory_window_directory}\n  {current_profile.advanced_working_directory_window_setting}")
    new_profile.set_initial_directory_mode(iterm2.InitialWorkingDirectory.INITIAL_WORKING_DIRECTORY_RECYCLE)

    jobName = await session.async_get_variable("jobName")
    commandLine = await session.async_get_variable("commandLine")
    was_sshed = jobName == "ssh"

    is_ssh = was_sshed and not force_local
    if was_sshed:
        if force_local:
            # force local means don't reconnect over SSH, open a local terminal
            # FYI, might want to address what happens when was_ssh b/c the path then if the ssh window was opened directly to SSH isn't going to be useful
            #    but, this might be where setting advanced_working_directory_* helps when I open a new window/tab/pane to track what local dir to come back to...
            #    OR, how about open it to home dir?
            new_profile.set_use_custom_command("No")
        else:
            new_profile.set_command(commandLine)
            new_profile.set_use_custom_command("Yes")
            # TODO also replicate bash over ssh on build21 for stract demos there?
    else:
        # * at least for duration of course, launch bash shell... when in bash in current session
        # that way no accidents when I don't realize I'm not in bash b/c I've replicated all my abbrs bash can feel like fish at times ;)
        was_bash = jobName == "bash"
        if force_local:
            # assume this means use fish
            # so I can ctrl+cmd+shift+t to open new tab to fish (just like I can do when ssh'ed to get back to fish local)
            pass
        elif was_bash:
            # if using bash (locally) then mirror that in new tab

            # inherit ONLY select Env Vars
            #
            # ITERM_SESSION_ID = os.environ['ITERM_SESSION_ID']  # ITERM_SESSION_ID=w0t1p0:F32B62FE-6BFB-4149-BACC-D9CDCFBF5508
            #   TODO does this come from shell integration script?
            #   ITERM_SESSION_ID='{ITERM_SESSION_ID}'
            #
            HOME = os.environ['HOME']
            bash_minimal_env = f"env -i HOME='{HOME}' /opt/homebrew/bin/bash --login"  # --login => will source profile startup files => i.e. /etc/profile (which on macOS sets up PATH (via /usr/libexec/path_helper -s)
            print(f'{bash_minimal_env=}')

            new_profile.set_command(bash_minimal_env)
            new_profile.set_use_custom_command("Yes")

    return new_profile, is_ssh

async def get_path(session: iterm2.Session) -> str:
    # default to using split_path to avoid issues with path being unreliable
    #   i.e. over SSH when running a program the path changes back to a local path!
    #     once program completes it reverts to remote path
    #     I capture split_path myself --on-variable PWD so it is always what I want
    split_path = await session.async_get_variable("user.split_path")
    if split_path is not None:
        print(f"using split_path: {split_path}")
        return split_path

    path = await session.async_get_variable("path")
    print(f"no split_path found, using path: {path}")
    return path

async def wes_new_window(connection: iterm2.Connection, force_local=False):
    prior_window = await get_current_window(connection)
    if prior_window is None:
        log("UNEXPECTED NO PRIOR WINDOW, opening new window")
        # this is not possible AFAIK right now b/c you have to have a window open to invoke keyboard monitor handlers
        await iterm2.Window.async_create(connection)
        return
    session = await get_current_session_throw_if_none(connection)
    new_profile, is_ssh = await prepare_new_profile(session, force_local)

    path = await get_path(session)

    new_window = await iterm2.Window.async_create(connection, profile_customizations=new_profile)
    if new_window is None:
        raise Exception("UNEXPECTED NO WINDOW CREATED")

    if force_local or not is_ssh:
        return

    new_session = get_current_session_for_window_throw_if_none(new_window)
    new_path = await new_session.async_get_variable("path")
    log(f"new_path: {new_path}, path: {path}")
    if new_path != path:
        await new_session.async_send_text(f"cd {path}; clear\n")
        # clear does same as Cmd+K (clears scrollback, not just screen)

async def wes_new_tab(connection, force_local=False):
    prior_window = await get_current_window_throw_if_none(connection)
    print(f"{prior_window.window_id=}")
    session = await get_current_session_throw_if_none(connection)
    new_profile, is_ssh = await prepare_new_profile(session, force_local)
    print()

    path = await get_path(session)

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
    new_profile, is_ssh = await prepare_new_profile(session, force_local)

    path = await get_path(session)

    new_session = await session.async_split_pane(vertical=split_vert, profile_customizations=new_profile)
    if new_session is None:
        raise Exception("UNEXPECTED NO SESSION CREATED")

    if force_local or not is_ssh:
        return

    await new_session.async_send_text(f"cd {path}; clear\n")
