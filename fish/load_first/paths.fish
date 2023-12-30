
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

# /snap/bin (ubuntu/wsl)
if test -d /snap/bin
    export PATH="/snap/bin:$PATH"
end

# ? fix ~/.dotnet/tools in path (replace with abs path) => see zshrc
