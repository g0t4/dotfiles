from re import I
import iterm2

import sys

clicked_path = sys.argv[1]
line_number = sys.argv[2]
text_before_click = sys.argv[3]
text_after_click = sys.argv[4]
working_directory = sys.argv[5]
repo_root = sys.argv[6]

print(f"py - clicked_path: {clicked_path}")
print(f"py - line_number: {line_number}")
print(f"py - text_before_click: {text_before_click}")
print(f"py - text_after_click: {text_after_click}")
print(f"py - working_directory: {working_directory}")
print(f"py - repo root: {repo_root}")


# exit(0) # for testing, uncomment to stop here

# foo
async def open_nvim_window(connection: iterm2.Connection):
    # neat thing is, this new nvim window if started with nvim then when nvim is closed, window closes too! no shell to go back to (so this becomes very much like what I had with vscode before)

    profile = iterm2.LocalWriteOnlyProfile()
    profile.set_custom_directory(repo_root)
    profile.set_initial_directory_mode(iterm2.InitialWorkingDirectory.INITIAL_WORKING_DIRECTORY_CUSTOM)

    # advanced dirs lets you set window/tab/pane specific dirs (not one working dir), so I don't need that for now
    # profile.set_advanced_working_directory_window_directory("/Users/wesdemos/repos")
    # profile.set_initial_directory_mode(iterm2.InitialWorkingDirectory.INITIAL_WORKING_DIRECTORY_ADVANCED)

    cmd = f"/opt/homebrew/bin/nvim '{clicked_path}'"
    if line_number:
        cmd += f" +{line_number}"
    profile.set_command(cmd)
    profile.set_use_custom_command("Yes")

    # IIUC command/profile_customizations are mutually exclusive
    window = await iterm2.Window.async_create(connection, profile_customizations=profile)


iterm2.run_until_complete(open_nvim_window)
