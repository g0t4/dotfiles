import iterm2
import asyncio
import traceback

from scrape_ask import copy_screen_to_clipboard
from f9command import on_f9
from logs import log
from og_ask import ask_openai
from split import close_other_tabs, new_tab_then_close_others, wes_split_pane, wes_new_tab, wes_new_window
from semantic_daemon import semantic_daemon
from font_zooms import bigger_font_wes_stops, smaller_font_wes_stops

async def main(connection: iterm2.Connection):

    async def keystroke_handler(keystroke: iterm2.Keystroke):
        # *** by registering a keystroke monitor in an iterm2 daemon, and reacting to just my keycombos... this script is warmed up and can immediately dispatch!!! shaves 1-2 seconds off of running a python script on keycombo instead... this is awesome

        control = iterm2.Modifier.CONTROL in keystroke.modifiers
        shift = iterm2.Modifier.SHIFT in keystroke.modifiers
        command = iterm2.Modifier.COMMAND in keystroke.modifiers
        option = iterm2.Modifier.OPTION in keystroke.modifiers

        # print_keystroke(keystroke)

        # FYI keystroke monitor only works if:
        #   - Script Console is not focused
        #   - iTerm2 window is focused
        #   - that means, if no iTerm2 windows are open, then keystroke monitor won't work
        #   WORKAROUND: use keyboard maestro to remap key combos and run an exteral script that uses iterm's python API... s/b fine
        #      one benefit: I don't have to reload the builtin wes.py script!

        # notes:
        #   AFAICT iterm won't let me remap builtin keys using a keystroke monitor alone
        #   there is an "Ignore" in Settings => Keys but then my monitor doesn't receive it either
        #     there is a "Script function" section but I cannot find any docs about what it does
        #     otherwise, pretty much can only remap to another existing command (limited subset too) and that sucks
        #     they should have a python handler alterantive or "Do Nothing" vs "Ignore" which squelches it
        #   so, in KMaestro I remap Cmd+N => Cmd+Shift+Control+N
        #     also Cmd+T => Cmd+Shift+Control+T
        # *** New Window helpers
        # FYI also had to remap Cmd+N => Cmd+Shift+Control+N in Keyboard Maestro
        n = keystroke.keycode == iterm2.Keycode.ANSI_N
        if n and control and shift and command:
            await wes_new_window(connection, force_local=False)
            return
        if n and command and control:
            await wes_new_window(connection, force_local=True)
            return

        # *** New Tab helpers
        # FYI also had to remap Cmd+T => Cmd+Shift+Control+T in Keyboard Maestro
        t = keystroke.keycode == iterm2.Keycode.ANSI_T
        if t and control and shift and command:
            await wes_new_tab(connection, force_local=False)
            return
        # FYI also had to remap Cmd+Shift+T in KM => Cmd+Ctrl+T
        #    cannot remap to same keys, wouldn't work :)
        if t and command and control:
            await wes_new_tab(connection, force_local=True)
            return

        # *** Split panes helpers (ssh support)
        # TODO for split pane, do I want an option to not do remote?
        #    LETS wait for it to be annoying and for now just assume split panes are always remote
        # FYI KM => remaps Cmd+D (split vert) => Cmd+Shift+Control+D
        # FYI   and Cmd+Shift+D (split horiz) => Cmd+Ctrl+Option+D
        #     avoid:
        #       (cmd+ctrl+d == define universally)
        #       (ctrl+alt+d == toggle dock)
        d = keystroke.keycode == iterm2.Keycode.ANSI_D
        if d and control and shift and command:
            await wes_split_pane(connection, split_vert=True)
            return
        if d and control and command and option:
            await wes_split_pane(connection, split_vert=False)
            return

        b = keystroke.keycode == iterm2.Keycode.ANSI_B
        if b and control and shift and command:
            await ask_openai(connection)
            return

        # keymap doesn't matter, just update streamdeck button if change this:
        d = keystroke.keycode == iterm2.Keycode.ANSI_X
        if d and control and shift and command:
            await close_other_tabs(connection)
            return

        # keymap doesn't matter, just update streamdeck button if change this:
        e = keystroke.keycode == iterm2.Keycode.ANSI_Y
        if e and control and shift and command:
            await new_tab_then_close_others(connection)
            return

        e = keystroke.keycode == iterm2.Keycode.ANSI_F
        if e and control and shift and command:
            # TODO merge with ANSI_B? should I just use this instead of ANSI_B approach?
            await copy_screen_to_clipboard(connection, history=False)
            return

        e = keystroke.keycode == iterm2.Keycode.ANSI_H
        if e and control and shift and command:
            await copy_screen_to_clipboard(connection, history=True)
            return

        e = keystroke.keycode == iterm2.Keycode.F9
        if e:
            await on_f9(connection)
            return

        e = keystroke.keycode == iterm2.Keycode.ANSI_MINUS
        if e and control and shift and command:
            await smaller_font_wes_stops(connection)
            return
        e = keystroke.keycode == iterm2.Keycode.ANSI_EQUAL
        if e and control and shift and command:
            await bigger_font_wes_stops(connection)
            return

    async def keystroke_monitor(connection):
        async with iterm2.KeystrokeMonitor(connection) as mon:
            while True:
                # unhandled exceptions take down the monitor so don't let that happen anymore!
                try:
                    keystroke = await mon.async_get()
                    await keystroke_handler(keystroke)
                except Exception as e:
                    log(f"unhandled exception in keystroke_monitor: {e}")
                    # dump stack trace
                    traceback.print_exc()

    asyncio.create_task(keystroke_monitor(connection))
    asyncio.create_task(semantic_daemon(connection))

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
