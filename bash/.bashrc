[[ -n "$WES_TRACE_STARTUP" ]] && (IFS="<" echo "sourcing ${BASH_SOURCE[*]}")

# ! KEEP THIS FILE MINIMAL, only critical, early config should be in here

# * uncomment for xtrace-ing (fyi.. can inherit path from outer shell)
# export PS1="$ "
# unset PROMPT_COMMAND # remove default for xtrace, when also comment out the return here:
# return

UNAME_S=$(uname -s)
is_macos() { [[ "$UNAME_S" = "Darwin" ]]; }
is_linux() { [[ "$UNAME_S" = "Linux" ]]; }

# * RUN BEFORE any path mods...
BASH_DOTFILES="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$BASH_DOTFILES/early/funcs.bash"
source "$BASH_DOTFILES/early/path-init.bash"
export WES_DOTFILES="$(realpath "$BASH_DOTFILES"/..)"

if is_macos; then

    prepend_path "/Applications/iTerm.app/Contents/Resources/utilities"

    export HOMEBREW_BAT=1

    # * below is hardcoded version of:
    #   eval $(brew shellenv bash)
    prepend_path "/opt/homebrew/bin"
    prepend_path "/opt/homebrew/sbin"
    export HOMEBREW_PREFIX="/opt/homebrew"
    export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
    export HOMEBREW_REPOSITORY="/opt/homebrew"
    [ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}"
    export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"

fi

prepend_path_if_exists ~/.local/bin

for script in "$BASH_DOTFILES/startup/first/"*.bash; do
    source "$script"
done
source "$BASH_DOTFILES/.generated.aliases.bash"
source "$BASH_DOTFILES/.generated.fish_func_wrappers.bash"
for script in "$BASH_DOTFILES/startup/"*.bash; do
    source "$script"
done
