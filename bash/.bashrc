( IFS="<"; echo "sourcing ${BASH_SOURCE[*]}")

# * uncomment for xtrace-ing (fyi.. can inherit path from outer shell)
# export PS1="$ "
# unset PROMPT_COMMAND # remove default for xtrace, when also comment out the return here:
# return

UNAME_S=$(uname -s)
is_macos() {
    [[ "$UNAME_S" = "Darwin" ]]
}

# * RUN BEFORE any path mods...
BASH_DOTFILES="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source "$BASH_DOTFILES/early/path-init.bash"
export WES_DOTFILES="$(realpath $BASH_DOTFILES/..)"

# * essential env vars (if not inherited)... i.e. if I `env -i` and don't pass any env vars
[[ -z "$TERM" || "$TERM" = dumb ]] && TERM=xterm-256color

export EDITOR=nvim
export PAGER=less
export LESS="-I -F -R"
export GREP_COLOR="1;38;5;162"
export WES_DOTFILES="$HOME/repos/github/g0t4/dotfiles"
export RIPGREP_CONFIG_PATH="$WES_DOTFILES/.config/ripgrep/ripgreprc"
export DOCKER_HIDE_LEGACY_COMMANDS=1
export KUBECTL_EXTERNAL_DIFF="icdiff -r"
export WATCH_INTERVAL=0.5
# export NODE_OPTIONS=--disable-warning=ExperimentalWarning
# export ICDIFF_OPTIONS="--highlight"
# VAGRANT_BOX_UPDATE_CHECK_DISABLE=
# VAGRANT_EXPERIMENTAL=
# VAGRANT_PROVIDER=





alias grep="grep --color=auto"

# PRN will iterm2 shell integration script setup this if I don't?
if is_macos; then

    # iterm's CLI tools  - i.e. imgcat
    prepend_path "/Applications/iTerm.app/Contents/Resources/utilities"

    # optional brew:
    export HOMEBREW_BAT=1

    # * below is hardcoded version of:
    #   eval $(brew shellenv bash)
    #
    #   another way to approach would be to run this once (in top level shell)
    #     using variable to determine if run when subshells launch...
    #     like I did with path init
    prepend_path "/opt/homebrew/bin"
    prepend_path "/opt/homebrew/sbin"
    #
    export HOMEBREW_PREFIX="/opt/homebrew"
    export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
    export HOMEBREW_REPOSITORY="/opt/homebrew"
    #
    [ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}"
    export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"

fi

for script in "$BASH_DOTFILES/startup/first/"*.bash; do
    source "$script"
done
source "$BASH_DOTFILES/.generated.aliases.bash"
for script in "$BASH_DOTFILES/startup/"*.bash; do
    source "$script"
done
