import time
import platform
import iterm2
import itertools

from common import get_current_session
from logs import log
from chat_stream import ask_openai_async_type_response

async def copy_screen_to_clipboard(connection: iterm2.Connection, history: bool = False):
    session = await get_current_session(connection)
    if session is None:
        log("No current session")
        return

    # if clear isn't possible I can still take full screen capture (like history) which would then have the commandline in it... and then the response I can paste anyways and then user can clear previous entry (yes cumbersome, just a possible workaround if needed - or mash the delete key :))
    ctrl_c = "\x03"
    ctrl_u = "\x15"
    clear_command = {
        "fish": ctrl_c,  # ctrl+c (my own binding)
        "lldb": ctrl_u,  # builtin
        "Python": ctrl_u,  # builtin
    }
    # FYI might want fallback mechanisms... i.e. my fish shell I have ctrl+C for clear but that is not standard... might be useful to detect if my config is loaded (i.e. user vars for other ask-openai path and if so then invoke other one else invoke fallback ctrl+e,ctrl+u  or ctrl+u => ctrl+k to clear (or is there a better way), I'm thinking mostly for remote systems w/o shell integration
    jobName = await session.async_get_variable("jobName")  # see inspector for vars
    log(f"jobName: {jobName}")
    if jobName is None:
        # probably should bail if I don't know if this will work
        return
    if jobName not in clear_command:
        log(f"jobName {jobName} not recognized, find and add its clear command to wes.py")
        return

    line_info = await session.async_get_line_info()
    lines = await session.async_get_contents(line_info.first_visible_line_number, line_info.first_visible_line_number + line_info.mutable_area_height)
    before_text = [line.string for line in lines]

    await session.async_send_text(clear_command[jobName])
    #
    # wait for clear
    time.sleep(0.1)  # otherwise sometimes command isn't cleared when I copy the after text
    # TODO OR can I wait for a change to screen instead of fixed delay?

    # PRN if there are other issues with scrollback...  fix as I encounter them... for now this seems to work good enough

    # get new screen contents
    lines = await session.async_get_contents(line_info.first_visible_line_number, line_info.first_visible_line_number + line_info.mutable_area_height)
    after_text = [line.string for line in lines]

    # *** diff (before has command, after doesn't)
    both = list(itertools.zip_longest(before_text, after_text, fillvalue=""))
    log(f"both: {list(both)}")
    # crude=> assumes before/after lines align and just need to subtract the after (clear cmd) from the before (cmd present):
    #   honestly does't need to be perfect b/c it is going to an LLM... infact,l maybe just send the screen?!
    changed_text = [line[0].replace(line[1], "") for line in both]
    changed_text = [l for l in changed_text if l != ""]
    log(f"diff: {changed_text}")
    current_command = "\n".join(changed_text)

    # GOOD testing seam:
    # pyperclip.copy(current_command)
    # return

    # try get ask_os from shell integration, should be correct unless using a remote that doesn't have shell integration in the underlying shell that launched the REPL that is running and complete here (i.e. fish + gdb)
    ask_os = await session.async_get_variable("user.ask_os")
    if ask_os is None:
        # fallback to iterm2's host os (not specific to a remote shell)
        ask_os = platform.system()

    # with python REPL, I had to be more specific than just 'shell: Python' => added REPL/shell comment (otherwise genreated 'ptyhon -c "print(1)"' which is not wanted in python REPL)
    user_content = f"env: I am using a {jobName} REPL/shell, on uname={ask_os}\nquestion: {current_command}"
    log(f"user_content: {user_content}")
    messages = [{
        "role": "system",
        "content": "You are a command line expert. Respond with a single, valid, complete command line. I intend to execute it. No explanation. No markdown. DO NOT respond with leading ``` nor trailing ```"
    }]

    await troubleshoot_lines(session)
    if history:
        previous = await get_previous_output(session)
        log(f"previous: {previous}")
        messages.append({"role": "user", "content": "here is previous output in my shell/REPL: \n" + previous})

    # append last, as it has question
    messages.append({"role": "user", "content": user_content})

    # await task_clear  # in this case, already waited for clear above

    # await session.async_send_text(f"{messages}") # quick double check in shell itself
    await ask_openai_async_type_response(session, messages)

async def get_previous_output(session: iterm2.Session):
    li = await session.async_get_line_info()

    # TODO verify further if this works?! I am still not 100% sure about scrolling positions but it looks like it might be ok

    # todo cap the history? (why not expect me to make judicious use of clear screen when I want help and want to limit what is passed? sounds good to me)
    # TODO get cursor line? and stop right before it?
    previous = await session.async_get_contents(0, li.first_visible_line_number + li.mutable_area_height)
    previous = [line.string for line in previous if line.string != ""]

    log("previous: " + str(previous))

    return "\n".join(previous)

async def troubleshoot_lines(session: iterm2.Session):
    gsc = await session.async_get_screen_contents()
    log("num_of_lines: " + str(gsc.number_of_lines))
    log("num_of_lines_above_screen: " + str(gsc.number_of_lines_above_screen))

    li = await session.async_get_line_info()
    log("first_visible_line_number: " + str(li.first_visible_line_number))
    log("mutable_area_height: " + str(li.mutable_area_height))
    log("overflow:" + str(li.overflow))
    log("scrollback_buffer_height: " + str(li.scrollback_buffer_height))

    visible = await session.async_get_contents(li.first_visible_line_number, li.first_visible_line_number + li.mutable_area_height)
    visible = [line.string for line in visible]
    log("visible: " + str(visible))
