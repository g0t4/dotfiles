# https://fishshell.com/docs/current/cmds/bind.html

function ask_use_anthropic
    set --universal ask_service --anthropic $argv
    ask_dump_config
end

function ask_use_deepseek
    set --universal ask_service --deepseek $argv
    ask_dump_config
end

function ask_use_groq
    set --universal ask_service --groq $argv
    ask_dump_config
end

function ask_use_openai_gpt4o
    set --universal ask_service --openai gpt-4o
    ask_dump_config
end

function ask_use_openai_gpt3
    set --universal ask_service --openai gpt-3.5-turbo-1106
    ask_dump_config
end

function ask_use_lmstudio
    set --universal ask_service --lmstudio $argv
    ask_dump_config
end

function ask_use_ollama_llama3

    set use_args $argv
    if test -z $use_args
        set use_args llama3 # default
    end

    set --universal ask_service --ollama $use_args

    ask_dump_config
end

function ask_dump_config
    echo "ask_service: $ask_service"
    echo
    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    set -l _single_py "$WES_DOTFILES/zsh/universals/3-last/ask-openai/single.py"
    $_python3 $_single_py $ask_service --dump_config
end

function ask_clear
    set --universal --erase ask_service
    ask_dump_config
end

function ask_openai

    set -l user_input (commandline -b)

    # FYI not appending '# thinking...' b/c it doesn't show AND doing so is messing up the prompt if a space typed before this func is invoked

    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    set -l _single_py "$WES_DOTFILES/zsh/universals/3-last/ask-openai/single.py"

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
            $_python3 $_single_py $ask_service 2>&1 \
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


# *** COMMAND COMPLETER...
function ask_openai_command_completer
    # PRN pass man page, --help/-h output to model to aide in completion?
    # set -l cmd (commandline -p) # -p == current process
    # set -l help (eval "$cmd --help 2>&1")
    # if test $status -ne 0
    #     set -l help ""
    # end

    # TODO
    #     # commandline -t (current token)
    #     #   -o/--tokenize
    #     #   -c/--cut-at-token
    #     #   -t/--current-token
    #     #   -p/--current-process
    #     #   -j/--current-job
    #     #   -b/--current-buffer
    # TODO cut at cursor position and only send that part?
    set -l user_input (commandline -b)

    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    set -l _script "$WES_DOTFILES/zsh/universals/3-last/ask-openai/completer.py"

    # set -l pass_stdin "user_input:"\n$user_input\n\n"BTW here is the output of '$cmd --help':"\n$help
    set pass_stdin $user_input
    echo -e $pass_stdin \
        | $_python3 $_script $ask_service 2>&1 # redir errors as completion options (can change later if I hate this)
end

#complete -c kubectl -a '(ask_openai_command_completer)' --no-files
complete -c ask -a '(ask_openai_command_completer)' --no-files
# complete -c security -a '(ask_openai_command_completer)' --no-files
# commands w/o completions on macos: security

# *** misc helpers for completions:

function __list_completions

    for path in $fish_complete_path
        echo $path
        for file in (ls $path)
            # indent each line so files are nested under their path
            echo "  $file"
        end
    end
end

function __find_completions_for

    # matches either:
    #   line starts with / (a path in fish_completions_path)
    #   line starts with 2 spaces (a file under a path) and name contains search term
    __list_completions | grep -E "^/|^  .*$argv.*"
    # PRN maybe just inline above __list_completions impl and use string match --regex to avoid brittle grep

end


## NOTES completions research
#
# tab delimit to add description:
# echo -e "get\tfoo the bar"
# echo -e "exec\tshel on in"
#
# can even modify commandline in completion func: commandline -a foo # => I could use this to rewrite the command line (i.e. trigger ask openai) by registering a custom completion func with some top level "ask" or "help" command (aside - could even setup real command so if I run it, it explains a solution too)... OMYGOSH => I could use completions (if it works) to propose multiple entire command line solutions and pick from them by tabbing?!
# idea: return entire command and have enter (or tab) delete first part of line or just have ask run whatever comes after? hrm => I don't like how it escapes every space but that actually probably makes sense given its suppopse to be a single token...
# set proc (commandline --tokenize)
# for token in $proc
#     echo "ls -al | ls -al | ls -al | ls -al | ls -al | ls -al | ls -al | ls -al | ls -al | ls -al"
#     echo "tree -a # other long command so we get a vertical menu of choices"
#     echo "ls -al | grep -i"
# end


# *** DO IT ***
function doit
    # NOT a key binding, used as a func "doit foo the bar for me"
    set -l user_input "$argv"

    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    set -l _script "$WES_DOTFILES/zsh/universals/3-last/ask-openai/doit.py"

    # $_python3 $_script $ask_service "$user_input"
    $_python3 $_script "$user_input"
end
function runit
    # NOT a key binding, used as a func "keyit foo.esh"
    set -l script_file "$argv"

    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    set -l _script "$WES_DOTFILES/zsh/universals/3-last/ask-openai/runit.py"

    # $_python3 $_script $ask_service "$user_input"
    $_python3 $_script "$script_file"
end
