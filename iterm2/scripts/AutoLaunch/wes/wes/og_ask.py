import platform
import iterm2

from common import get_current_session
from logs import log
from asyncs import ask_openai_async_type_response


async def ask_openai(connection):

    # BTW b/c most variables/info is extracted via iterm2 shell integration, this works with remote shells that have iterm2 shell integration installed & sourced!

    session = await get_current_session(connection)
    if session is None:
        return

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
    # BTW ctrl+c must be bound in the shell to clear the line, i.e. in fish: bind ctrl-c 'commandline -f kill'

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

    user_content = f"env: shell={ask_shell} on uname={ask_os} and FYI lastCommand={env_last_command}\nquestion: {current_command}"
    messages = [{
        "role": "system",
        "content": "You are a command line expert. Respond with a single, valid commandline. I intend to execute it. No explanation. No markdown. DO NOT respond with leading ``` nor trailing ```"
    }, {
        "role": "user",
        "content": user_content
    }]
    log(f"messages: {user_content}")

    await task_clear  # ? why can't I put this after try/catch (smth happens with timing to not actually clear the prompt if I do that, but only on remote pi7.lan?)

    try:
        await ask_openai_async_type_response(session, messages)
    except Exception as e:
        failure = f"Failure getting OpenAI response {e}"
        await session.async_send_text(failure)

