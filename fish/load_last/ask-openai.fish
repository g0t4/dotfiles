# https://fishshell.com/docs/current/cmds/bind.html

function ask_openai

    # get buffer (not including suggestion, if visible, just user input)
    set -l user_input (commandline -b)
    # https://fishshell.com/docs/current/cmds/commandline.html

    # ** TODO can I get # thinking to show (IIAC prompt won't update until this function completes?) # not end of world if I can't show "thinking"
    # # if user_input ends with space:
    # if string match --regex " \$" $user_input
    #     commandline "$user_input# thinking"
    # else
    #     # w/o args should overwrite buffer
    #     commandline "$user_input # thinking"
    # end

    # ! fix when last char of user input is space (suggests showing),  it causes prompt to redraw on next line (yuck), I'm not sure this is b/c suggests b/c suggestes show with file/path and if no space at end they don't mess up prompt
    # w/o thinking.. space on end always results in prompt redrawn (even if suggestions never show)
    commandline -f repaint # ? hack => this partially fixed the prompt to fully redraw on next line and not wrap in a funky way

    set -l _python3 "$WESCONFIG_BOOTSTRAP/.venv/bin/python3"
    set -l _single_py "$WES_DOTFILES/zsh/universals/3-last/ask-openai/single.py"

    set -l response ( \
        echo -e "env: fish on $(uname)\nquestion: $user_input" | \
        $_python3 $_single_py 2>&1 \
    )
    set -l exit_code $status
    if test $exit_code -eq 2
        commandline --replace "[CONTEXT]: $response"
    else if test $exit_code -ne 0
        commandline --replace "[FAIL]: $response"
    else
        commandline --replace $response
    end
    # todo repaint? when to do that and not to?

end

bind \cb ask_openai
# FYI \ch # ctrl+h is unused in fish (IIUC from reading bind output), `h` would be ok to use too (help)
