# https://fishshell.com/docs/current/cmds/bind.html

function ask_openai

    set -l user_input (commandline -b)

    # FYI not appending '# thinking...' b/c it doesn't show AND doing so is messing up the prompt if a space typed before this func is invoked

    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    set -l _single_py "$WES_DOTFILES/zsh/universals/3-last/ask-openai/single.py"

    set -l response ( \
        echo -e "env: fish on $(uname)\nquestion: $user_input" | \
        $_python3 $_single_py 2>&1 \
    )
    set -l exit_code $status
    if test $exit_code -eq 2
        commandline --replace "[CONTEXT]: $response"
        # FYI other causes rc=2 print as context (i.e. wrong path to python script, NBD as error shows anyways)
    else if test $exit_code -ne 0
        commandline --replace "[FAIL]: $response"
    else
        commandline --replace $response
    end
    # FYI ctrl+z can undo replacment

    # `fish_commandline_append` doesn't use repaint, so I assume I don't need to
end

# how does fish handle multiple registrations? does last one win? is it an issue that \cb is preset bound to backward-char?
bind \cb ask_openai



function ask_openai_explain
    # *** UNDO to get command back? OR, explain in comment? that way can keep command visible and still undo cmd+z
    set -l user_input (commandline -b)

    # FYI not appending '# thinking...' b/c it doesn't show AND doing so is messing up the prompt if a space typed before this func is invoked

    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    set -l _explain_py "$WES_DOTFILES/zsh/universals/3-last/ask-openai/explain.py"

    set -l response ( \
        echo -e "env: fish on $(uname)\nquestion: $user_input" | \
        $_python3 $_explain_py 2>&1 \
    )
    set -l exit_code $status
    if test $exit_code -eq 2
        commandline --replace "[CONTEXT]: $response"
        # FYI other causes rc=2 print as context (i.e. wrong path to python script, NBD as error shows anyways)
    else if test $exit_code -ne 0
        commandline --replace "[FAIL]: $response"
    else
        commandline --replace $response
    end
    # FYI ctrl+z can undo replacment

    # `fish_commandline_append` doesn't use repaint, so I assume I don't need to
end

bind -k f2 ask_openai_explain


function ask_openai_link
    # TODO ideas
    #   return first url to help me understand the command better
    #   need to differentiate which command I am struggling with, esp if multiple (so where am I likely having issues or not understanding)
    #   diff semantic vs syntactic questions/issues/lookups
    #   just like with generating a command, use comments after to explain what I want to do and/or to modify the command
    #   find the most helpful resource (i.e. docker container run => https://docs.docker.com/reference/cli/docker/container/run)
    #   can't be hallucinating URLs... needs to confirm the link before responding to me? can I do that over the API?

    set -l user_input (commandline -b)

    # FYI not appending '# thinking...' b/c it doesn't show AND doing so is messing up the prompt if a space typed before this func is invoked

    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    set -l _link_py "$WES_DOTFILES/zsh/universals/3-last/ask-openai/link.py"

    set -l response ( \
        echo -e "env: fish on $(uname)\nquestion: $user_input" | \
        $_python3 $_link_py 2>&1 \
    )
    set -l exit_code $status
    if test $exit_code -eq 2
        commandline --replace "[CONTEXT]: $response"
        # FYI other causes rc=2 print as context (i.e. wrong path to python script, NBD as error shows anyways)
    else if test $exit_code -ne 0
        commandline --replace "[FAIL]: $response"
    else
        commandline --replace $response
    end
    # FYI ctrl+z can undo replacment

    # `fish_commandline_append` doesn't use repaint, so I assume I don't need to
end


bind -k f3 ask_openai_link
# urls? shotgun style! open up to 5 tabs!?

## NOTES
#
# PRN use background job/process like in zsh so # thinking... shows up in prompt
#    async-prompt: https://github.com/acomagu/fish-async-prompt/blob/master/conf.d/__async_prompt.fish
#    cursory review shows this doing basically what I did in zsh with &!
#
# `fish_key_reader` to find a given key combo => type Ctrl+e => shows \ce
# `bind --function-names` list special funcs
#   https://fishshell.com/docs/current/cmds/bind.html#special-input-functions
# `bind -L` => list modes
#   `default` mode unless -M/-m passed
# `bind` => list bindings (add -a for all)
# `bind \cb` => show what is bound to key sequence
#   `bind ''` => self-insert (types key) (default key binding if seq not bound)
#   `bind ' '` => space => self-insert & expand-abbr
