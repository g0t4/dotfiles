import platform
import iterm2
import re
from client import get_ask_client
import pyperclip
import difflib
import itertools
import time
from scrape_ask import copy_screen_to_clipboard
from f9command import on_f9

DEBUG = True


async def main(connection: iterm2.Connection):

    async def keystroke_handler(keystroke: iterm2.Keystroke):
        # *** by registering a keystroke monitor in an iterm2 daemon, and reacting to just my keycombos... this script is warmed up and can immediately dispatch!!! shaves 1-2 seconds off of running a python script on keycombo instead... this is awesome

        control = iterm2.Modifier.CONTROL in keystroke.modifiers
        shift = iterm2.Modifier.SHIFT in keystroke.modifiers
        command = iterm2.Modifier.COMMAND in keystroke.modifiers

        b = keystroke.keycode == iterm2.Keycode.ANSI_B
        if b and control and shift and command:
            await ask_openai(connection)

        d = keystroke.keycode == iterm2.Keycode.ANSI_D
        if d and control and shift and command:
            await close_other_tabs(connection)

        e = keystroke.keycode == iterm2.Keycode.ANSI_E
        if e and control and shift and command:
            await new_tab_then_close_others(connection)

        e = keystroke.keycode == iterm2.Keycode.ANSI_F
        if e and control and shift and command:
            # spike an idea for a new type of ask-openai that doesn't need iterm2 shell integration (use running program to trigger actions and diff screen contents to copy the command)
            await copy_screen_to_clipboard(connection)

        e = keystroke.keycode == iterm2.Keycode.F9
        if e:
            await on_f9(connection)

    async with iterm2.KeystrokeMonitor(connection) as mon:
        while True:
            keystroke = await mon.async_get()
            await keystroke_handler(keystroke)


async def close_other_tabs(connection):
    app = await iterm2.async_get_app(connection)
    current_tab = app.current_terminal_window.current_tab
    for tab in current_tab.window.tabs:
        if tab != current_tab:
            await tab.async_close()


async def new_tab_then_close_others(connection):
    app = await iterm2.async_get_app(connection)

    prior_window = app.current_terminal_window

    # make new tab and close all other tabs in current window
    new_tab = await prior_window.async_create_tab()
    for tab in prior_window.tabs:
        if tab != new_tab:
            await tab.async_close(force=True)


def log(msg):
    # FYI check Cmd+Alt+J to see iterm2 logs (script console), with this output
    if not DEBUG:
        return
    print(msg)


async def ask_openai(connection):

    # BTW b/c most variables/info is extracted via iterm2 shell integration, this works with remote shells that have iterm2 shell integration installed & sourced!

    # *** get current terminal session
    app = await iterm2.async_get_app(connection)
    window = app.current_terminal_window
    if window is None:
        print("No current terminal window")
        return
    session = window.current_tab.current_session

    # *** get current command line text
    prompt = await iterm2.prompt.async_get_last_prompt(connection, session.session_id)
    if prompt is None:
        # i.e. IIGC right after sourcing iterm2 shell integration, wouldn't yet have a last prompt.. very rare but don't want to crash this script
        failure = "No last prompt, are you missing iterm2 shell integration?"
        log(failure)
        await session.async_send_text(failure)
        return
    current_command = prompt.command
    log(f"current_command: {current_command}")  # 18us to print
    if current_command is None:
        failure = "No current command, are you missing iterm2 shell integration?"
        log(failure)
        await session.async_send_text(failure)
        return
    # *** clear prompt (start)
    task_clear = session.async_send_text("\x03")  # ctrl+c (start clear commandline), seems snappier than starting this after contacting openai
    # BTW ctrl+c must be bound in the shell to clear the line, i.e. in fish: bind \cc 'commandline -f kill'

    # *** read ask_* vars:
    #   user.ask_* variables are set in the shell (on prompt redraw) using iterm2_print_user_vars/iterm2_set_user_var via iterm2 shell integration
    ask_shell = await session.async_get_variable("user.ask_shell")
    if ask_shell is None:
        # fallback to iterm2's shell variable (not specific to a remote shell)
        ask_shell = await session.async_get_variable("shell")
        if ask_shell is None:
            ask_shell = "unknown"

    ask_os = await session.async_get_variable("user.ask_os")
    if ask_os is None:
        # fallback to iterm2's host os (not specific to a remote shell)
        ask_os = platform.system()
        # good use of ask_os is for `apt install` vs `brew install` vs `yum install` on RHEL, type "install netstat" and run on mac/debian and see the difference

    # FYI last_comand is not critical, can probably be removed, I just added it b/c it was there... not sure it will ever be that helpful and I loved my single.py w/o it forever now...
    env_last_command = await session.async_get_variable("lastCommand")  # FYI works on remotes w/ iterm2 shell integration

    use, client = get_ask_client()

    messages = [{
        "role":
        "system",
        "content":
        "You are a command line expert. Respond with a single, valid, complete command line. I intend to execute it. No explanation. No markdown. DO NOT respond with leading ``` nor trailing ```"
    }, {
        "role": "user",
        "content": f"env: shell={ask_shell} on uname={ask_os} and FYI lastCommand={env_last_command}\nquestion: {current_command}"
    }]
    log(f"messages: {messages[1]['content']}")

    await task_clear  # ? why can't I put this after try/catch (smth happens with timing to not actually clear the prompt if I do that, but only on remote pi7.lan?)

    if use.name == "anthropic":
        # PRN impl streaming anthropic here based on httpx only
        # TODO impl it elsewhere and plug it in here, testing by restarting wes.py is a PITA
        from single import get_anthropic_suggestion
        command = get_anthropic_suggestion(current_command, use)
        await session.async_send_text(command)
        return

    # *** request completion
    try:
        response_stream = await client.chat.completions.create(
            model=use.model,
            messages=messages,
            max_tokens=200,
            # TODO temperature?
            stream=True)
    except Exception as e:
        # TODO test timeouts?
        log(f"Error contacting OpenAI: {e}")
        await session.async_send_text(f"Error contacting API endpoint: {e}")
        return

    # *** stream the reponse chunks
    # TODO write some tests for sanitizing and use a seam here

    first_chunk = True
    async for chunk in response_stream:
        # FYI w.r.t ``` ... deepseek-chat listens to request to not use ``` and ``` but deepseek-coder always returns ```... that actually makes sense for the coder...
        if chunk.choices[0].delta.content is not None:
            # strip new lines to avoid submitting commands prematurely, is there an alternate char I could use to split the lines still w/o submitting (would have to check what the shell supports, if anything is possible)... one downside to not being a part of the line editor.. unless there is a workaround? not that I care much b/c multi line commands are not often necessary...
            sanitized = chunk.choices[0].delta.content.replace("\n", " ")
            if first_chunk:
                print(f"first_chunk: {sanitized}")
                sanitized = re.sub(r'```', '', sanitized).lstrip()
                print(f"sanitized: {sanitized}")
                print(f"sanitized hex: {sanitized.encode('utf-8').hex()}")
                first_chunk = sanitized == ""  # stay in "first_chunk" mode until first non-empty chunk
                await session.async_send_text(sanitized)
            else:
                await session.async_send_text(sanitized)
            # TODO is there a way to detect last chunk?
    # after last chunk, can I remove ending ``` and spaces? it might span multiple last chunks btw so wouldn't just be able to keep track of last chunk, would need entire response and then detect if ends with ``` and spaces and then delete those chars?
    # ideally I would have some sort of streaming mechanism that would detect leading/trailing ``` and spaces... and then no correction is needed to delete chars`


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
#    FYI I have a symlink from ~/Library/Application Support/iTerm2/Scripts -> /Users/wes/repos/wes-config/wes-bootstrap/subs/dotfiles/iterm2/scripts
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
