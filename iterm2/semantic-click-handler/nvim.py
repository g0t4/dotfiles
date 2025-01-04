import iterm2


async def open_nvim_window(connection: iterm2.Connection):
    # neat thing is, this new nvim window if started with nvim then when nvim is closed, window closes too! no shell to go back to (so this becomes very much like what I had with vscode before)
    profile = iterm2.LocalWriteOnlyProfile()
    profile.set_custom_directory("/Users/wesdemos/repos")
    profile.set_initial_directory_mode(iterm2.InitialWorkingDirectory.INITIAL_WORKING_DIRECTORY_CUSTOM)

    # advanced dirs lets you set window/tab/pane specific dirs (not one working dir), so I don't need that for now
    # profile.set_advanced_working_directory_window_directory("/Users/wesdemos/repos")
    # profile.set_initial_directory_mode(iterm2.InitialWorkingDirectory.INITIAL_WORKING_DIRECTORY_ADVANCED)

    profile.set_command("/opt/homebrew/bin/nvim")
    profile.set_use_custom_command("Yes")

    # IIUC command/profile_customizations are mutually exclusive
    window = await iterm2.Window.async_create(connection, profile_customizations=profile)


iterm2.run_until_complete(open_nvim_window)
