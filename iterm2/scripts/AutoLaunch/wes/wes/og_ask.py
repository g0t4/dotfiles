import platform
import iterm2
import rich

from common import get_current_session
from logs import log
from chat_stream import ask_openai_async_type_response


async def fix_xonsh_get_commandline(connection, session, prompt):
    print(rich.inspect(prompt))
    # in xonsh,
    #  with prompt.command I get back the first word reliably (think command position)
    #  and then rarely I will get two words or more, but often not the full command line
    #  BUT, I always get correct command ranges so I can scrape the text myself to ensure it is fixed
    #  only caveat is I also then get \x00 between words (where I have spaces)
    #  this is likely whey the command line is cut off in prompt.command

    subselection = iterm2.SubSelection(
        iterm2.WindowedCoordRange(prompt.command_range),
        iterm2.SelectionMode.CHARACTER,
        connected=False,
    )

    command = await subselection.async_get_string(
        connection,
        session.session_id,
    )
    return command.replace("\x00", " ")


async def ask_openai(connection):
    session = await get_current_session(connection)
    if session is None:
        return

    # *** determine running shell
    commandLine = await session.async_get_variable("commandLine")
    is_xonsh = commandLine == "xonsh"
    jobName = await session.async_get_variable("jobName")
    which_shell = jobName
    if is_xonsh:
        which_shell = "xonsh"
    print(f'{jobName=} {is_xonsh=} {which_shell=}')

    async def clear_line():
        ctrl_c = "\x03"
        ctrl_u = "\x15"
        clear_command = {
            "fish": ctrl_c,  # ctrl+c (my own binding)
            "lldb": ctrl_u,  # builtin
            "Python": ctrl_u,  # builtin
            # "xonsh": TODO
        }
        if which_shell is None or which_shell not in clear_command:
            log(f"{which_shell=} not recognized, defaulting to ctrl+c")
            clear_cmd = ctrl_c
        else:
            clear_cmd = clear_command[which_shell]
        await session.async_send_text(clear_cmd)

    prompt = await iterm2.prompt.async_get_last_prompt(connection, session.session_id)
    if prompt is None:
        # i.e. IIGC right after sourcing iterm2 shell integration, wouldn't yet have a last prompt.. very rare but don't want to crash this script
        failure = "No last prompt, are you missing iterm2 shell integration?"
        log(failure)
        await session.async_send_text(failure)
        return
    current_command = prompt.command
    if is_xonsh:
        current_command = await fix_xonsh_get_commandline(connection, session, prompt)
    log(f"{current_command=}")  # 18us to print

    if current_command is None:
        failure = "No current command, are you missing iterm2 shell integration?"
        log(failure)
        await session.async_send_text(failure)
        return

    # *** clear prompt (start)
    task_clear = clear_line()

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

    # FYI last_comand is not essential, sometimes it is useful to provide recent a recent command as context (and then I can just ask a question and it sees prior command to apply question to)
    env_last_command = await session.async_get_variable("lastCommand")  # FYI works on remotes w/ iterm2 shell integration

    user_content = f"env: shell={ask_shell} on uname={ask_os} and FYI lastCommand={env_last_command}\nquestion: {current_command}"
    messages = [{
        "role": "system",
        "content": "You are a command line expert. Respond with a single, valid commandline. I intend to execute it. No explanation. No markdown. DO NOT respond with leading ``` nor trailing ```"
    }, {
        "role": "user",
        "content": user_content \
    }]

    await task_clear  # ? why can't I put this after try/catch (smth happens with timing to not actually clear the prompt if I do that, but only on remote pi7.lan?)

    try:
        await ask_openai_async_type_response(messages, session.async_send_text, clear_line)
    except Exception as e:
        failure = f"Failure getting OpenAI response {e}"
        await session.async_send_text(failure)
