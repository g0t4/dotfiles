# https://fishshell.com/docs/current/cmds/bind.html

function ask_openai

    set -l user_input (commandline -b)

    # FYI not appending '# thinking...' b/c it doesn't show AND doing so is messing up the prompt if a space typed before this func is invoked

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

    # `fish_commandline_append` doesn't use repaint, so I assume I don't need to
end

bind \cb ask_openai
# FYI \ch # ctrl+h is unused in fish (IIUC from reading bind output), `h` would be ok to use too (help)

## NOTES
# FYI:
#   `fish_commandline_append` => appends to buffer (read that impl to learn how its done)

# `fish_key_reader` to find a given key combo => \ce
# `bind --function-names` list speical funcs
#   `bind -L` => list modes
#   `bind` => list bindings (add -a for all)
#   `bind \cb` => show what is bound to key sequence
#       `bind ''` => self-insert (types key) (default key binding if seq not bound)
#       `bind ' '` => space => self-insert & expand-abbr
#            appears that multiple bindings can apply to a given key seq (IIUC registered via separate calls to bind, or multiple commands passed to singe bind call)
#   `default` mode unless -M/-m passed
#   special input funcs: https://fishshell.com/docs/current/cmds/bind.html#special-input-functions
