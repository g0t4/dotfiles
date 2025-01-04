from re import I
import iterm2

import sys

# leave all args even if unused so they are always available AND always in the same order
clicked_path = sys.argv[1]
line_number = sys.argv[2]
text_before_click = sys.argv[3]
text_after_click = sys.argv[4]
working_directory = sys.argv[5]
workspace_root = sys.argv[6]  # keep separate of workign_directory b/c working_directory is passed by iterm2 when it invokes the semantic click handler so I wanna preserve verbatim what iterm2 passed

print(f"py - clicked_path: {clicked_path}")
print(f"py - line_number: {line_number}")
print(f"py - text_before_click: {text_before_click}")
print(f"py - text_after_click: {text_after_click}")
print(f"py - working_directory: {working_directory}")
print(f"py - workspace_root: {workspace_root}")


# avoid none soup 4 levels deep in consumer code... feels like a better way to do this (later)
# for now just log why something is missing, if it is missing, otherwise return the level I want
async def get_current_window(connection: iterm2.Connection):
    app = await iterm2.async_get_app(connection)
    if app is None:
        log("No current app")
        return
    window = app.current_window
    if window is None:
        log("No current terminal window")
    return window


async def get_current_tab(connection: iterm2.Connection):
    window = await get_current_window(connection)
    if window is None:
        return
    tab = window.current_tab
    if tab is None:
        log("No current tab")
    return tab


async def get_session(connection: iterm2.Connection):
    tab = await get_current_tab(connection)
    if tab is None:
        return
    session = tab.current_session
    if session is None:
        log("No current session")
        return
    return session


# exit(0) # for testing, uncomment to stop here
async def open_nvim_window(connection: iterm2.Connection):
    session = await get_session(connection)
    if session is None:
        return

    current_profile = await session.async_get_profile()
    with open("output.txt", "w") as f:
        f.write(str(vars(current_profile)))

    current_font = current_profile.normal_font
    # i.e. SauceCodeProNF 12
    #   IIUC can have other things after size? or? (see example below)
    # example of altering font size:
    # https://iterm2.com/python-api/examples/increase_font_size.html#increase-font-size-example

    # neat thing is, this new nvim window if started with nvim then when nvim is closed, window closes too! no shell to go back to (so this becomes very much like what I had with vscode before)
    # PRN in future, if I click multiple files in same workspace... don't open new nvim window? or should I just do that? ... i.e. if perusing ag command matches and want to open up a few in nvim... I am thinking it s/b fine to close nvim/reopen each time, for now s/b fast enough... if I have trouble with speed (i.e. starting plugins each time) then investigate in a method to dedupe (only for this semantic click handler) windows per workspace

    new_profile = iterm2.LocalWriteOnlyProfile()
    new_profile.set_custom_directory(workspace_root)
    new_profile.set_initial_directory_mode(iterm2.InitialWorkingDirectory.INITIAL_WORKING_DIRECTORY_CUSTOM)

    new_profile.set_normal_font(current_font)
    # PRN preserve other profile settings...?

    # TODO match zoom level of current window (where click happened)... so dont have to adjust zoom every time too...
    #   just a thought, but what if I could set zoom for nvim in general based on workspace!... interesting...

    # advanced dirs lets you set window/tab/pane specific dirs (not one working dir), so I don't need that for now
    # profile.set_advanced_working_directory_window_directory("/Users/wesdemos/repos")
    # profile.set_initial_directory_mode(iterm2.InitialWorkingDirectory.INITIAL_WORKING_DIRECTORY_ADVANCED)

    cmd = f"/opt/homebrew/bin/nvim '{clicked_path}'"
    if line_number:
        cmd += f" +{line_number}"
        # FYI use `ag foo` to test line number matches (click file:# in output)
    new_profile.set_command(cmd)
    new_profile.set_use_custom_command("Yes")

    # command/profile_customizations are mutually exclusive, thus pass command with profile_customizations
    window = await iterm2.Window.async_create(connection, profile_customizations=new_profile)


iterm2.run_until_complete(open_nvim_window)
