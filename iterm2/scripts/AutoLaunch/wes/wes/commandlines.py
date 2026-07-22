import iterm2
import rich

from common import *


async def yank_last_command_output_and_paste_to_commandline(connection):

    await iterm2.MainMenu.async_select_menu_item(
        connection,
        "Select Output of Last Command",
    )

    # * get selection
    session = await get_current_session_throw_if_none(connection)
    selection = await session.async_get_selection()
    last_output = await session.async_get_selection_text(selection)
    # FYI see alternative in get_previous_output that also gets previous command output to ask AI about it! interesting!
    # ? TODO? cycle command outputs (last command, n-1, n-2, etc) with the screen reading APIs used by get_previous_output in scrape_ask.py
    #  think alt+dot in fish shell

    # FYI I am leaving this just in case I need to troubleshoot as I start to use this...
    rich.print(f'{last_output=}')

    # * clear selection
    selection.sub_selections.clear()
    await session.async_set_selection(selection)

    # * paste into commandline
    paste_this = last_output.replace("\n", "")  # send_text will type the \n
    # PRN I could escape and insert a \n sequence (as if I typed \n) if that works for a given situation but lets wait until I need it
    #  largely right now I want single values as single args... we shall see what I come up with next (if anything else)
    rich.print(f'{paste_this=}')
    await session.async_send_text(paste_this)
    # FYI async_inject merely writes chars to PTY... shell never sees them
    # - must use send_text for shell to see them and then it will echo them to STDOUT like you'd get with inject)

    # FYI! examples
    # fd weskill # a file named that
    # cd <path from fd weskill output>  # btw my cd command will cd to a file too hence I can do this with full path to file!
    #    PRN add support for taking only last path when fd and when multiple lines in output?
    #
    # git rev-parse ORIG_HEAD
    # git show ___
    #   yes I can alt+dot to get ORIG_HEAD... however sometimes I want the sha value
    #   PRN would be cool to detect + shorten sha values to 8 chars automatically?!
    #
    # PRN if I typed pbcopy should I echo the output to pbcopy? ... maybe a custom shortcut for that?
    #   so "pbcopy" => "echo LAST_STDOUT | pbcopy" ?
    #   for now no... I can type "echo <C-Cmd-A> | pbcopy" is fine!
    #
