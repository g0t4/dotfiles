[[ -n "$WES_TRACE_STARTUP" ]] && (IFS="<" echo "sourcing ${BASH_SOURCE[*]}")

# # * uncomment for xtrace-ing (fyi.. can inherit path from outer shell)
# export PS1="\W $ "
# unset PROMPT_COMMAND # remove default for xtrace, when also comment out the return here:
# return

UNAME_S=$(uname -s)
is_macos() { [[ "$UNAME_S" = "Darwin" ]]; }
is_linux() { [[ "$UNAME_S" = "Linux" ]]; }

# * RUN BEFORE any path mods...
BASH_DOTFILES="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$BASH_DOTFILES/startup/vetted-benign/early/funcs.bash"
source "$BASH_DOTFILES/startup/vetted-benign/early/path-init.bash"
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

# * Force prepend custom build of bash
force_prepend_path ~/repos/github/g0t4/bash

prepend_path_if_exists ~/.local/bin

for script in "$BASH_DOTFILES/startup/vetted-benign/first/"*.bash; do
    source "$script"
done
source "$BASH_DOTFILES/.generated.paredabbrs.bash"
source "$BASH_DOTFILES/.generated.fish_func_wrappers.bash"

for script in "$BASH_DOTFILES/startup/vetted-benign/"*.bash; do
    source "$script"
done
for script in "$BASH_DOTFILES/startup/course-only/"*.bash; do
    source "$script"
done

# remove if any issues:
source ~/.iterm2_shell_integration.bash
# curl -L https://iterm2.com/shell_integration/bash -o ~/.iterm2_shell_integration.bash

# * testing macro:
# function test {
#     READLINE_LINE="echo hello"
#     READLINE_POINT=11
#     return 124
# }
# bind -x '"\C-g": "test"'

# ** warn if not using custom build:
[[ "$BASH_VERSION" == 5.3.3* ]] || echo "unexpected bash version: $BASH_VERSION"
[[ "$BASH" == ~/repos/github/g0t4/bash/bash ]] || echo "NOT USING CUSTOM BUILD OF BASH: $BASH"
# echo "$BASH_VERSION"
