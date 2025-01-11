import iterm2
import subprocess

from common import get_session
from logs import log


def send_cmd_k_to_iterm2():
    apple_script = '''
    tell application "iTerm2"
        tell current session of current window
            select
            tell application "System Events"
                keystroke "k" using command down
            end tell
        end tell
    end tell
    '''
    try:
        subprocess.run(["osascript", "-e", apple_script], check=True)
        print("Cmd+K sent to iTerm2 successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Failed to send Cmd+K to iTerm2: {e}")


async def new_cmd_k_clear(connection):

    session = await get_session(connection)
    if session is None:
        return

    # TODO determine if shell integration is setup and working OR not
    #  TOOD IF NOT send regular clear command (cmd+k but make sure not handled in circular way)

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

    # *** determine if prompt has prev failed command so I don't need to return again for no reason?
    if current_command != "":
        task_clear = session.async_send_text("\x03")  # ctrl+c (start clear commandline), seems snappier than starting this after contacting openai
        # wait?
        await task_clear

    await session.async_send_text("\n")

    if current_command != "":
        # put prompt back
        await session.async_send_text(current_command)

    send_cmd_k_to_iterm2()
