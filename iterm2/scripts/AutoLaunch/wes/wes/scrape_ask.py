import time
import platform
import iterm2
import re
from client import get_ask_client
import pyperclip
import difflib
import itertools

async def copy_screen_to_clipboard(connection):
    app = await iterm2.async_get_app(connection)
    window = app.current_terminal_window
    if window is None:
        print("No current terminal window")
        return
    session = window.current_tab.current_session
    if session is None:
        print("No current session")
        return

    # send ctrl+c to fish shell to clear line (w/o copy) - FYI this is my custom keymap... just use it here for testing b/c I should be using the othher ask-openai below with my fish config
    # ctrl+u for lldb
    clear_command = {"fish": "\x03", "lldb": "\x15", "-fish": "\x03"}
    # FYI might want fallback mechanisms... i.e. my fish shell I have ctrl+C for clear but that is not standard... might be useful to detect if my config is loaded (i.e. user vars for other ask-openai path and if so then invoke other one else invoke fallback ctrl+e,ctrl+u  or ctrl+u => ctrl+k to clear (or is there a better way), I'm thinking mostly for remote systems w/o shell integration
    jobName = await session.async_get_variable("jobName")  # see inspector for vars
    print(f"jobName: {jobName}")
    if jobName is None:
        # probably should bail if I don't know if this will work
        return
    if jobName not in clear_command:
        print(f"jobName {jobName} not recognized, find and add its clear command to wes.py")
        return

    line_info = await session.async_get_line_info()
    print(f"line_info: {line_info}")
    lines = await session.async_get_contents(0, 10)
    before_text = [line.string for line in lines]
    # pyperclip.copy(text)

    await session.async_send_text(clear_command[jobName])
    #
    # wait for clear
    time.sleep(0.1)  # otherwise sometimes command isn't cleared when I copy the after text
    # TODO OR can I wait for a change to screen instead of fixed delay?

    # get new screen contents
    lines = await session.async_get_contents(0, 10)
    after_text = [line.string for line in lines]

    # *** diff
    both = list(itertools.zip_longest(before_text, after_text, fillvalue=""))
    print(f"both: {list(both)}")
    # crude=> assumes before/after lines align and just need to subtract the after (clear cmd) from the before (cmd present):
    #   honestly does't need to be perfect b/c it is going to an LLM... infact,l maybe just send the screen?!
    changed_text = [line[0].replace(line[1], "") for line in both]
    changed_text = [l for l in changed_text if l != ""]
    print(f"diff: {changed_text}")
    # TODO concat lines? or?
    pyperclip.copy("\n".join(changed_text))

    # type fucker
    await session.async_send_text("fucker")

