# https://fishshell.com/docs/current/cmds/bind.html

function _ask_write_state
    # TODO get rid of fish universal variable? or? what is file read overhead? <2ms??? hopefully if so then get rid of fish universal variable to simplify logic
    set --universal ask_service $argv

    mkdir -p ~/.local/share/ask-openai/
    echo "$argv" >~/.local/share/ask-openai/service
    ask_dump_config
end

function ask_dump_config
    echo "ask_service: $ask_service"
    echo "file: $(cat ~/.local/share/ask-openai/service)"
    # PRN I could add pythons script to create client and dump use like before, but lets see if I even need it
end

function ask_clear
    _ask_write_state
end

function ask_use_anthropic
    _ask_write_state --anthropic $argv
end

function ask_use_deepseek
    _ask_write_state --deepseek $argv
end

function ask_use_inception
    _ask_write_state --inception $argv
end

function ask_use_xai
    _ask_write_state --xai $argv
end

function ask_use_groq
    _ask_write_state --groq $argv
end

function ask_use_openai
    # FYI let the service code handle the default model, dont duplicate that logic here
    _ask_write_state --openai $argv
end

function ask_use_lmstudio
    _ask_write_state --lmstudio $argv
end

function ask_use_ollama
    _ask_write_state --ollama $argv
end

function ask_use_vllm
    _ask_write_state --vllm $argv
end

function get_openai_models

    # if first arg is ollama, use that instaed:
    if test "$argv[1]" = ollama
        set base_url http://ollama:11434/v1/models
        set api_key ""
    else if test "$argv[1]" = groq
        set base_url https://api.groq.com/openai/v1/models
        set api_key (security find-generic-password -s groq -a ask -w)
    else if test "$argv[1]" = deepseek
        set base_url https://api.deepseek.com/v1/models
        set api_key (security find-generic-password -s deepseek -a ask -w)
    else if test "$argv[1]" = vllm
        set base_url http://ollama:8000/v1/models
        set api_key ""
    else if test "$argv[1]" = inception
        set base_url https://api.inceptionlabs.ai/v1/models
        set api_key (security find-generic-password -s inception -a ask -w)
    else if test "$argv[1]" = xai
        set base_url https://api.x.ai/v1/models
        set api_key (security find-generic-password -s xai -a ask -w)
    else
        set base_url https://api.openai.com/v1/models
        set api_key (security find-generic-password -s openai -a ask -w)
    end

    curl -H "Authorization: Bearer $api_key" \
        --fail-with-body \
        -sSL $base_url \
        | jq ".data[].id" -r

end

complete --command ask_use_ollama --no-files -a '(get_openai_models ollama)'
complete --command ask_use_openai --no-files -a '(get_openai_models)'
complete --command ask_use_groq --no-files -a '(get_openai_models groq)'
complete --command ask_use_inception --no-files -a '(get_openai_models inception)'
complete --command ask_use_deepseek --no-files -a '(get_openai_models deepseek)'
complete --command ask_use_vllm --no-files -a '(get_openai_models vllm)'
complete --command ask_use_xai --no-files -a '(get_openai_models xai)'

function ask_openai

    set -l user_input (commandline -b)

    # FYI not appending '# thinking...' b/c it doesn't show AND doing so is messing up the prompt if a space typed before this func is invoked

    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    set -l _single_py "$WES_DOTFILES/zsh/universals/3-last/ask-openai/single.py"
    set -l _single_rs "$WES_DOTFILES/zsh/universals/3-last/ask-openai/rusts/target/debug/rusts"

    if string match --regex -q "git commit -m" $user_input
        # *** future => ask openai first for any supplementary info it may want (based on user_input) and then I can query that and pass it with normal question and it can decide when I am committing and want a suggested commit description and ask for git_diff and I provide it... so I could have a list of context functions (git_diff, list_files, pwd, ip_addys, etc) it can ask to be invoked and passed with user_input ... also could just pass all the contextual info upfront and not have back and forth which is premature optimization most likely! until I get a ton of background data that might confuse things I could just provide all of it every time?
        # ? give it recent commit messages too?
        # if using git commit => pass git diff and ask it to write a commit message
        set git_diff (git diff --cached --no-color)
        set response ( \
            echo -e "env: fish on $(uname)\nquestion: write me a commit message, here is the git diff:\n$git_diff" | \
            $_python3 $_single_py $ask_service 2>&1 \
        )
    else
        set response ( \
            echo -e "env: fish on $(uname)\nquestion: $user_input" | \
            $_single_rs 2>&1 \
        )
    end
    set exit_code $status
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
bind_both_modes_default_and_insert ctrl-b ask_openai



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

bind_both_modes_default_and_insert f2 ask_openai_explain


function ask_openai_link

    set -l user_input (commandline -b)

    # FYI not appending '# thinking...' b/c it doesn't show AND doing so is messing up the prompt if a space typed before this func is invoked

    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    set -l _link_py "$WES_DOTFILES/zsh/universals/3-last/ask-openai/link.py"

    set -l response ( \
        echo -e "env: $(uname)\nquestion: $user_input" | \
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


bind_both_modes_default_and_insert f3 ask_openai_link
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
# `bind ctrl-b` => show what is bound to key sequence
#   `bind ''` => self-insert (types key) (default key binding if seq not bound)
#   `bind ' '` => space => self-insert & expand-abbr
