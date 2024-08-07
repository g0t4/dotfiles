
# if not status is-login
#     return
# end

# ! this must run early, including before auto-venv-on-cd b/c otherwise deactivate venv removes these PATH changes (reverts to PATH before venv was activated)

# PRN if other scripts need HOMEBREW_PREFIX then move this earlier in startup scripts
# if homebrew is present, add env vars/PATH
if test -f /opt/homebrew/bin/brew
    # apple silicon macs
    eval $(/opt/homebrew/bin/brew shellenv)
else if test -f /usr/local/bin/brew
    # intel macs
    eval $(/usr/local/bin/brew shellenv)
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
# ~/.local/bin
if test -d "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
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

# ? fix ~/.dotnet/tools in path (replace with abs path) => see zshrc

### COMPLETIONS path:
if test -d $WES_DOTFILES/fish/completions/
    # - FYI autoloaded at Completion Time per command name (foo<TAB> loads foo.fish)
    # - Use for complex completions (i.e. ensure slow completions are lazy loaded)
    # - Use to override other completions
    # - Otherwise it's ok to inline completions (where command is defined)
    set fish_complete_path $WES_DOTFILES/fish/completions/ $fish_complete_path
end

if test -d $WES_DOTFILES/fish/functions/
    # - FYI autoloaded when respective command name is first run (and periodically reloaded)
    set fish_function_path $WES_DOTFILES/fish/functions/ $fish_function_path
end

# ghcup (haskell)
if test -d "$HOME/.ghcup/bin"
    export PATH="$HOME/.ghcup/bin:$PATH"
    # FYI
    # ghcup list --tool ghc
    # ghcup set ghc latest/recommended
end
