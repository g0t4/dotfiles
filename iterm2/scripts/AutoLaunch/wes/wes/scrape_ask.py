import time
import platform
import iterm2
import itertools

from common import get_session
from logs import log
from asyncs import ask_openai_async_type_response


async def copy_screen_to_clipboard(connection: iterm2.Connection):
    session = await get_session(connection)
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
    rows = line_info.mutable_area_height
    lines = await session.async_get_contents(0, rows)
    before_text = [line.string for line in lines]

    await session.async_send_text(clear_command[jobName])
    #
    # wait for clear
    time.sleep(0.1)  # otherwise sometimes command isn't cleared when I copy the after text
    # TODO OR can I wait for a change to screen instead of fixed delay?

    # get new screen contents
    lines = await session.async_get_contents(0, rows)
    after_text = [line.string for line in lines]

    # *** diff (before has command, after doesn't)
    both = list(itertools.zip_longest(before_text, after_text, fillvalue=""))
    print(f"both: {list(both)}")
    # crude=> assumes before/after lines align and just need to subtract the after (clear cmd) from the before (cmd present):
    #   honestly does't need to be perfect b/c it is going to an LLM... infact,l maybe just send the screen?!
    changed_text = [line[0].replace(line[1], "") for line in both]
    changed_text = [l for l in changed_text if l != ""]
    print(f"diff: {changed_text}")
    current_command = "\n".join(changed_text)

    # GOOD testing seam:
    # pyperclip.copy(current_command)
    # return

    # TODO extract shared logic with the other ask-openai async script! will be cool to do this async too!

    # try get ask_os from shell integration, should be correct unless using a remote that doesn't have shell integration in the underlying shell that launched the REPL that is running and complete here (i.e. fish + gdb)
    ask_os = await session.async_get_variable("user.ask_os")
    if ask_os is None:
        # fallback to iterm2's host os (not specific to a remote shell)
        ask_os = platform.system()

    user_content = f"env: shell={jobName} on uname={ask_os}\nquestion: {current_command}"
    messages = [{
        "role": "system",
        "content": "You are a command line expert. Respond with a single, valid, complete command line. I intend to execute it. No explanation. No markdown. DO NOT respond with leading ``` nor trailing ```"
    }, {
        "role": "user",
        "content": user_content
    }]
    log(f"messages: {user_content}")

    # await task_clear  # in this case, already waited for clear above

    await ask_openai_async_type_response(session, messages)
