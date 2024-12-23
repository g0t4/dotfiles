import time
import platform
import iterm2
import re
from client import get_ask_client
import pyperclip
import difflib
import itertools

from common import get_session

# CELEBRATORY pointless commit ... w00000h000000000 it works!!!! first try dumping all that shit below and w00t.. I just got help in lldb with ask-openai!!

# TODO MAKE COMMON VERSION AND TOGGLE
DEBUG = True


def log(msg):
    # FYI check Cmd+Alt+J to see iterm2 logs (script console), with this output
    if not DEBUG:
        return
    print(msg)


async def copy_screen_to_clipboard(connection: iterm2.Connection):
    app = await iterm2.async_get_app(connection)

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
    current_command = "\n".join(changed_text)
    # pyperclip.copy(current_command) # don't need now!

    # TODO extract shared logic with the other ask-openai async script! will be cool to do this async too!

    # try get ask_os from shell integration, should be correct unless using a remote that doesn't have shell integration in the underlying shell that launched the REPL that is running and complete here (i.e. fish + gdb)
    ask_os = await session.async_get_variable("user.ask_os")
    if ask_os is None:
        # fallback to iterm2's host os (not specific to a remote shell)
        ask_os = platform.system()

    use, client = get_ask_client()

    messages = [{
        "role":
        "system",
        "content":
        "You are a command line expert. Respond with a single, valid, complete command line. I intend to execute it. No explanation. No markdown. DO NOT respond with leading ``` nor trailing ```"
    }, {
        "role": "user",
        "content": f"env: shell={jobName} on uname={ask_os}\nquestion: {current_command}"
    }]
    # TODO LOGGING like other scripts (have toggle in one spot)
    print(f"messages: {messages[1]['content']}")

    # await task_clear  # ? why can't I put this after try/catch (smth happens with timing to not actually clear the prompt if I do that, but only on remote pi7.lan?)
    # ALREADY cleared b/c I had to, to get the diff (hopefully clear!)

    # TODO uncomment and patch up anthropic support when I MERGE this with other one in a comomn helper
    # if use.name == "anthropic":
    #     # PRN impl streaming anthropic here based on httpx only
    #     # TODO impl it elsewhere and plug it in here, testing by restarting wes.py is a PITA
    #     from single import get_anthropic_suggestion
    #     command = get_anthropic_suggestion(current_command, use)
    #     await session.async_send_text(command)
    #     return

    # *** request completion
    try:
        response_stream = await client.chat.completions.create(model=use.model, messages=messages, max_tokens=200, stream=True)
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
