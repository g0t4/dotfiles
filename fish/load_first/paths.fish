# if not status is-login
#     return
# end

# ! this must run early, including before auto-venv-on-cd b/c otherwise deactivate venv removes these PATH changes (reverts to PATH before venv was activated)

# PRN if other scripts need HOMEBREW_PREFIX then move this earlier in startup scripts
# if homebrew is present, add env vars/PATH
if test -f /opt/homebrew/bin/brew
    # apple silicon macs

    # eval $(/opt/homebrew/bin/brew shellenv) # 30ms to run this so don't do it on every startup...
    # *** generated code:
    set --global --export HOMEBREW_PREFIX /opt/homebrew
    set --global --export HOMEBREW_CELLAR /opt/homebrew/Cellar
    set --global --export HOMEBREW_REPOSITORY /opt/homebrew
    fish_add_path --global --move --path /opt/homebrew/bin /opt/homebrew/sbin
    if test -n "$MANPATH[1]"
        set --global --export MANPATH '' $MANPATH
    end
    if not contains /opt/homebrew/share/info $INFOPATH
        set --global --export INFOPATH /opt/homebrew/share/info $INFOPATH
    end
    # *** end generated code

else if test -f /usr/local/bin/brew
    # intel macs
    #eval $(/usr/local/bin/brew shellenv)
    echo "brew shellenv not implemented yet, do this if you ever use an intel mac again"
end

# export PATH="$HOME/bin:$PATH"
# export PATH="$HOME/go/bin:$PATH"
# export PATH="$HOME/.local/bin:$PATH"

# ~/bin
if test -d "$HOME/bin"
    export PATH="$HOME/bin:$PATH"
end
# ~/go/bin
if test -d "$HOME/go/bin"
    export PATH="$HOME/go/bin:$PATH"
end
if test -d /usr/local/go/bin
    # from wget install (see fish/install/install.fish)
    export PATH="/usr/local/go/bin:$PATH"
end
# ~/.local/bin
if test -d "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
end
if test -d "$HOME/.cargo/bin"
    export PATH="$HOME/.cargo/bin:$PATH"
end

if test -d "$HOME/repos/github/zed-industries/zed/target/debug"
    # target debug build of zed (comment out when done using it as daily driver)
    export PATH="$HOME/repos/github/zed-industries/zed/target/debug:$PATH"
end

# kubectl krew
if test -d "$HOME/.krew/bin"
    # suggested by krew:
    # set -q KREW_ROOT; and set -gx PATH $PATH $KREW_ROOT/.krew/bin; or set -gx PATH $PATH $HOME/.krew/bin

    # I will just go with ~/.krew/bin
    export PATH="$HOME/.krew/bin:$PATH"
end

# /snap/bin (ubuntu/wsl)
if test -d /snap/bin
    export PATH="/snap/bin:$PATH"
end

# ? fix ~/.dotnet/tools in path (replace with abs path) => see zshrc (ignore wrong path in /etc/paths.d/dotnet-cli-tools with ~/.dotnet/tools)
if test -d "$HOME/.dotnet/tools"
    # make dotnet tool install --global work (add to PATH)
    export PATH="$HOME/.dotnet/tools:$PATH"
end

### COMPLETIONS path:
# TODO find a way to block bundled completions when they suck, like this one for curl:
#   trash /opt/homebrew/Cellar/fish/4.0.2/share/fish/completions/curl.fish
#   it is missing dozens of flags and yet...
#    for example: --fail-with-body
#   and yet the one from fuc works great (at least with missing options like --fail-with-body):
#     /Users/wesdemos/.cache/fish/generated_completions/curl.fish
#   for now I trashed the above one, but I should come up with a more viable approach
#    maybe symlink fuc ones to my completions dir or a second completions dir? OR just put all fuc ones in front of bundled completions?
#
#   for p in $fish_complete_path ; fd curl $p; end

function find_fish_completion_for_cmd_regex
    # usage:
    # find_fish_completion_for_cmd_regex "pgrep"
    # find_fish_completion_for_cmd_regex "pg.*"
    set cmd $argv[1]
    for dir in $fish_complete_path
        if not test -d $dir
            continue
        end

        fd --full-path completions/$cmd.fish $dir
    end
end
function list_terrible_completions_present
    echo "completions with issues in the past (empty list == good):"
    fd --full-path completions/curl.fish /opt/homebrew/Cellar/fish
    # TODO long term find a way around this issue... i.e. submit a patch to upstream or... put just this one from fuc ahead of bundled?
    # issue is the bundled ones should be superior to fuc generated ones...  so I cannot just put fuc first
    # by the way  fuc == fish_update_completions
end
if test -d $WES_DOTFILES/fish/completions/
    # - FYI autoloaded at Completion Time per command name (foo<TAB> loads foo.fish)
    # - Use for complex completions (i.e. ensure slow completions are lazy loaded)
    # - Use to override other completions
    # - Otherwise it's ok to inline completions (where command is defined)
    set fish_complete_path $fish_complete_path $WES_DOTFILES/fish/completions/
end

if test -d $WES_DOTFILES/fish/functions/
    # - FYI autoloaded when respective command name is first run (and periodically reloaded)
    set fish_function_path $fish_function_path $WES_DOTFILES/fish/functions/
end

# ghcup (haskell)
if test -d "$HOME/.ghcup/bin"
    export PATH="$HOME/.ghcup/bin:$PATH"
    # FYI
    # ghcup list --tool ghc
    # ghcup set ghc latest/recommended
end

function use_brew_llvm
    export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
end

if test -d "/opt/homebrew/opt/postgresql@17/bin"
    # todo should I warn if newer or other version is installed instead?
    #  btw v14 is the "default" version in homebrew, why? why not v17?
    #  also if I use `brew link postgresql@17` it appends _17 on end of all commands which YUCK hence adding here:
    export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
end

# google-cloud-sdk
if test -d /opt/homebrew/share/google-cloud-sdk/bin
    export PATH="/opt/homebrew/share/google-cloud-sdk/bin:$PATH"
end

if test -d "$HOME/repos/github/ggml-org/llama.cpp/build/bin"
    # TODO is this what I want?
    export PATH="$HOME/repos/github/ggml-org/llama.cpp/build/bin:$PATH"
    set GGUF_MODELS "$HOME/repos/github/ggml-org/llama.cpp/models"
end

# /opt/cuda/bin/
if test -d /opt/cuda/bin
    export PATH="/opt/cuda/bin:$PATH"
end

# ~/.npm-global/bin
if test -d "$HOME/.npm-global/bin"
    export PATH="$HOME/.npm-global/bin:$PATH"
end

# Rancher Desktop (IIGC created once user creates a cluster)
# ~/.rd/bin"
if test -d "$HOME/.rd/bin"
    export PATH="$PATH:$HOME/.rd/bin"
end

if test -d "$HOME/bin"
    # i.e. fennel-ls
    export PATH="$PATH:$HOME/bin"
end

# *** PATH(s)

function _path_list
    # think which, but not limited to the which command you are using
    #   i.e. zsh's builtin which is not same as system /usr/bin/which which other shells like fish use
    for dir in $PATH
        if test -e $dir
            for item in $dir/*
                echo $dir$item
            end
            # PRN any filtering or additional info to show? i.e. file type? dir? etc...?
        end
    end
end

# # /opt/watchman/bin/
# if test -d /opt/watchman/bin
#     export PATH="$PATH:/opt/watchman/bin"
# end

# PRN lm-studio
# set -gx PATH $PATH /Users/wesdemos/.cache/lm-studio/bin
