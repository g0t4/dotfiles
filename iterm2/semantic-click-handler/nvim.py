from re import I
import iterm2
import os
from common import get_session, get_current_window, get_current_tab
from logs import log
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


# FYI test this w/o literally clicking in iterm2 (i.e. tree output in this sematnic-click-handler dir and click on nvim.fish):
#   ./nvim.fish  $WES_DOTFILES/iterm2/semantic-click-handler/nvim.py "" "" "" $WES_DOTFILES/iterm2/semantic-click-handler $WES_DOTFILES

# exit(0) # for testing, uncomment to stop here
async def open_nvim_window(connection: iterm2.Connection):
    session = await get_session(connection)
    if session is None:
        return

    current_profile = await session.async_get_profile()
    # with open("profile.txt", "w") as f:
    #     f.write(str(vars(current_profile)))
    #  FYI: pretty print profile.txt:
    #    cat profile.txt | yq --prettyPrint

    # neat thing is, this new nvim window if started with nvim then when nvim is closed, window closes too! no shell to go back to (so this becomes very much like what I had with vscode before)
    # PRN in future, if I click multiple files in same workspace... don't open new nvim window? or should I just do that? ... i.e. if perusing ag command matches and want to open up a few in nvim... I am thinking it s/b fine to close nvim/reopen each time, for now s/b fast enough... if I have trouble with speed (i.e. starting plugins each time) then investigate in a method to dedupe (only for this semantic click handler) windows per workspace

    new_profile = iterm2.LocalWriteOnlyProfile()
    new_profile.set_custom_directory(workspace_root)
    new_profile.set_initial_directory_mode(iterm2.InitialWorkingDirectory.INITIAL_WORKING_DIRECTORY_CUSTOM)

    new_profile.set_normal_font(current_profile.normal_font)
    # i.e. SauceCodeProNF 12
    #   IIUC can have other things after size? or? (see example below)
    # example of altering font size:
    # https://iterm2.com/python-api/examples/increase_font_size.html#increase-font-size-example
    # PRN preserve other profile settings...?
    #
    # ASIDE: font size, I wonder if I would find it useful to have font size tied to the workspace (like other nvim settings)... not an easy feat to accomplish but you could observe font size (profile changes) changes and then store it per workspace and then what would you do, when opening just one of these nvim windows then apply that size? Maybe this would be a size for these nvim dedicated windows only? interesting...

    # PRN adjust other profile settings... i.e. maybe a diff background color (slightly) to remind me its nvim only or smth minor?

    # advanced dirs lets you set window/tab/pane specific dirs (not one working dir), so I don't need that for now
    # profile.set_advanced_working_directory_window_directory("/Users/wesdemos/repos")
    # profile.set_initial_directory_mode(iterm2.InitialWorkingDirectory.INITIAL_WORKING_DIRECTORY_ADVANCED)

    # FYI can wrap in fish shell if I need the shell env to get nvim to work (i.e. coc requires smth I have in my shell dotfiles... and so it works if use fish -c nvim but not nvim directly, currently)
    #    repro w/o click handler:
    #         env -i (which nvim) # PATH not even set here
    #         => run `:!env` and observe no PATH
    #    test that PATH fixes issue:
    #         # clear entir env except PATH (copy that from outer fish shell):
    #         env -i PATH=(string join : $PATH) (which nvim)
    #    diff PATHs:
    #         icdiff (for p in $PATH; echo $p; end | psub) (env -i (which fish) -c "for p in \$PATH; echo \$p; end" | psub)
    #
    # both of these are closable too.. IOTW neither returns to shell if you quit nvim so either is fine for me for now:
    # fish_to_nvim_cmd = f"/opt/homebrew/bin/fish -c 'nvim {clicked_path}'"
    nvim_directly_cmd = f"/opt/homebrew/bin/nvim {clicked_path}"
    # ok set path with env command works too, much better than fish -c overhead
    #   BTW much of env vars are inherited by new nvim standalone process... but not PATH
    use_this_path = f"{os.environ['PATH']}"
    nvim_inherit_path_cmd = f"env PATH='{use_this_path}' {nvim_directly_cmd}"
    #
    cmd = nvim_inherit_path_cmd
    if line_number:
        cmd += f" +{line_number}"
        # FYI use `ag foo` to test line number matches (click file:# in output)
    new_profile.set_command(cmd)
    new_profile.set_use_custom_command("Yes")

    # command/profile_customizations are mutually exclusive, thus pass command with profile_customizations
    window = await iterm2.Window.async_create(connection, profile_customizations=new_profile)


## NOTES:
#  - try open new window/tab/pane in nvim popup window and that just opens another nvim instance, not necessarily a bad thing! ... just FYI, think about it
#    - for now keep terminal panes in a new / separate window to avoid this (perfectly fine, in fact kinda how I wanted it)...
#    - intereswting to think you can easily open new instances of same workspace in nvim with Cmd+T here... might be useful for smth else
# - what about clicking several files (i.e. ag output multiple matches, open each one by one)... can we open in same instance of nvim (and/or a new tab in same window?)... is that important or not?
#    - mostly I am worried about perf to load nvim for each file... but maybe wait until that is a real pain first

iterm2.run_until_complete(open_nvim_window)
