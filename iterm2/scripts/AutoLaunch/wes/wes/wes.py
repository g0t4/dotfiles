import iterm2
import asyncio
import traceback

from commandlines import yank_last_command_output_and_paste_to_commandline
from scrape_ask import copy_screen_to_clipboard
from f9command import on_f9
from logs import log
from og_ask import ask_openai
from split import (
    close_other_tabs,
    new_tab_then_close_others,
    wes_split_pane,
    wes_replace_pane,
    wes_new_tab,
    wes_new_window,
)
from semantic_daemon import semantic_daemon
from font_zooms import bigger_font_wes_stops, smaller_font_wes_stops


async def main(connection: iterm2.Connection):

    # The original implementation used a keystroke monitor to trigger actions.
    # All functionality is now exposed via RPC calls, allowing external tools
    # (e.g., Stream Deck, Keyboard Maestro) to invoke the actions directly.
    asyncio.create_task(semantic_daemon(connection))

    # * map these into keymaps in iterm settings so there's no need for KM remapping nonsense
    # FYI I mapped
    #  cmd+d => vertical split (replaces builtin keymap)
    #  cmd+d+shift => horizontal split (replaces builtin keymap to do this with current profile and/or just no profile)

    @iterm2.RPC
    async def wes_keymap_split_vertical_pane():
        await wes_split_pane(connection, split_vert=True)

    @iterm2.RPC
    async def wes_keymap_split_horizontal_pane():
        await wes_split_pane(connection, split_vert=False)

    @iterm2.RPC
    async def wes_keymap_new_tab():
        log("NEW TAB")
        await wes_new_tab(connection, force_local=False)

    @iterm2.RPC
    async def wes_keymap_new_tab_force_local():
        log("NEW TAB FORCE_LOCAL")
        await wes_new_tab(connection, force_local=True)

    @iterm2.RPC
    async def wes_keymap_new_tab_then_close_others():
        # FYI IIRC only use this via streamdeck button (use keymap as intermediary)
        #  probably could have streamdeck button call some python code to invoke this?
        log("NEW TAB THEN CLOSE OTHERS")
        await new_tab_then_close_others(connection)

    @iterm2.RPC
    async def wes_keymap_new_window():
        log("NEW WINDOW")
        await wes_new_window(connection, force_local=False)

    @iterm2.RPC
    async def wes_keymap_new_window_force_local():
        log("NEW WINDOW FORCE_LOCAL")
        await wes_new_window(connection, force_local=True)

    @iterm2.RPC
    async def wes_keymap_replace_pane():
        log("REPLACE PANE")
        await wes_replace_pane(connection, force_local=False)

    @iterm2.RPC
    async def wes_keymap_smaller_font():
        await smaller_font_wes_stops(connection)

    @iterm2.RPC
    async def wes_keymap_bigger_font():
        await bigger_font_wes_stops(connection)

    @iterm2.RPC
    async def wes_keymap_ask_openai():
        log("ASK OPENAI")
        await ask_openai(connection)

    @iterm2.RPC
    async def wes_keymap_close_other_tabs():
        # key_x and control and command and shift
        await close_other_tabs(connection)

    @iterm2.RPC
    async def wes_keymap_copy_screen_to_clipboard():
        # key_f and control and command and shift
        await copy_screen_to_clipboard(connection, history=False)

    @iterm2.RPC
    async def wes_keymap_copy_screen_to_clipboard_history():
        # key_h and control and command and shift
        await copy_screen_to_clipboard(connection, history=True)

    @iterm2.RPC
    async def wes_keymap_f9():
        # TODO map F9 so it can fall through to neovim too?
        await on_f9(connection)

    @iterm2.RPC
    async def wes_keymap_yank_last_command_output():
        # key_a and control and command
        await yank_last_command_output_and_paste_to_commandline(connection)

    # * registers
    await wes_keymap_split_vertical_pane.async_register(connection)
    await wes_keymap_split_horizontal_pane.async_register(connection)
    #
    await wes_keymap_new_tab.async_register(connection)
    await wes_keymap_new_tab_force_local.async_register(connection)
    await wes_keymap_new_tab_then_close_others.async_register(connection)
    #
    await wes_keymap_new_window.async_register(connection)
    await wes_keymap_new_window_force_local.async_register(connection)
    #
    await wes_keymap_replace_pane.async_register(connection)
    await wes_keymap_smaller_font.async_register(connection)
    await wes_keymap_bigger_font.async_register(connection)
    #
    await wes_keymap_ask_openai.async_register(connection)

    # Register additional RPCs formerly bound to keystrokes
    await wes_keymap_close_other_tabs.async_register(connection)
    await wes_keymap_copy_screen_to_clipboard.async_register(connection)
    await wes_keymap_copy_screen_to_clipboard_history.async_register(connection)
    await wes_keymap_f9.async_register(connection)
    await wes_keymap_yank_last_command_output.async_register(connection)


iterm2.run_forever(main)

#
#
# NOTES - reproducible installs on other accounts/machines:
#   - i.e. iterm2env python stuffs
#   - btw can launch with this:
#       ~/Applications/iTerm.app/Contents/Resources/it2run (pwd)/wes/
#       https://iterm2.com/python-api/tutorial/running.html
#

# ****** pypi deps
#    have to setup as iterm2 script with full env... not sure yet how to mirror this across machines... figure that out later
#    FYI Scripts => Manage => Manage Dependencies => pick script => Add button => sometimes this fails, if so run the command it shows (pip install) at the command line and it will work
#    /Users/wes/.config/iterm2/AppSupport/Scripts/ask-openai/streaming-ask-openai/iterm2env/versions/3.10.4/bin/pip3 list    # list packages for "basic env" iterm2 scripts (not full env)
#    /Users/wes/.config/iterm2/AppSupport/Scripts/ask-openai/streaming-ask-openai/iterm2env/versions/3.10.4/bin/pip3 install openai    # FYI may not show up in list that iterm2 shows but doesn't matter, as long as its installed it should work fine
#       BTW: ls -al /Users/wes/.config/iterm2/AppSupport -> /Users/wes/Library/Application Support/iTerm2
#    FYI ignored iterm2env dir... might have to copy that between machines at first? who knows... learn how iterm2 sets up these envs and see if I cannot find a reproducible way?
#    FYI I have a symlink from ~/Library/Application Support/iTerm2/Scripts -> ~/repos/github/g0t4/dotfiles/iterm2/scripts
#       so make sure this is setup on other machines/accounts too
#

# IDEAS:
#   - implement functions to allow tools to be used to gather further info about the environment, i.e. run a tool to find what package managers are installed and report back so the right package install command is generated, just an idea, only consider this if I have a problem w/o tools

# alt invocation triggers:
#        @iterm2.ContextMenuProviderRPC can add to context menu, is there a way to add to regular menus?! could then bypass keystroke monitor for some actions (above)

#
# *** If you’d like your script to launch automatically when iTerm2 starts, move it to $HOME/Library/ApplicationSupport/iTerm2/Scripts/AutoLaunch.

# *** iterm variables
#   BTW variables => Console => INSPECTOR => Variables tab => shows values per tab (move between tabs to refresh)
#   other vars of interest: path

# *** prompt notes
#   prompt https://iterm2.com/python-api/prompt.html#iterm2.Prompt
#   prompts = await iterm2.prompt.async_list_prompts(connection, session.session_id)

# *** send key combos to the shell as if typed (using ascii codes => unicode escaped (hex))
#   unicode_escape (ascii codes) https://en.wikipedia.org/wiki/ASCII
#   await session.async_send_text("\x03") # ctrl+c # https://en.wikipedia.org/wiki/ASCII => \x03 (hex) => ETX => Ctrl+C
#   await session.async_send_text("\x1bk")  # esc+k => (must be lowercase k) => custom keybinding in my shells to yank (copy) + kill (clear)
#   PRN restore clipboard after done copying current command?
#     For now, leave in clipboard so it can be pasted
#     (b/c chunk responses mean ctrl+z undo is hassle unlike a single final response in single.py)
# *** clipboard to get command
#   clipboard_content = pyperclip.paste()

# *** PRN set user variables in shell that are readable in iterm2 via this python API
#   FYI I can communicate "user" defined variables (from shell into iTerm2 variables under "user") via iterm2_print_user_vars => define it as a func, have it call `iterm2_set_user_var foo bar` and then its called every time it communicates other vars (RemoteHost and CurrentDir vars) => then async_get_variable("user.foo") to get value in here! this appears to be called before/after every command (or prompt IIUC) => https://iterm2.com/documentation-scripting-fundamentals.html#setting-user-defined-variables
#    PRN could call this on every keystroke to not need to yank command line... though yanking works fine!
#
#
# *** get screen contents => literally can get text from the entire screen (line by line)
#   what = await session.async_get_screen_contents()  # gets screen contents, now, can I deliniate current command line position from this? that would work then to show me the command!
#   cursor = what.cursor_coord
#   cursor_line = cursor.y
#   print(what.line(cursor_line).string)  # works to get line with cursor!
#
#   FYI I could write the prompt to a file too, i.e. for windows t
#
#   await iterm2.MainMenu.async_select_menu_item(connection, "About iTerm2")
#   await iterm2.MainMenu.async_select_menu_item(connection, "Select Current Command")  # w0000t
