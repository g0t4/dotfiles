( IFS="<"; echo "sourcing ${BASH_SOURCE[*]}")


UNAME_S=$(uname -s)
is_macos() {
    [[ "$UNAME_S" = "Darwin" ]]
}

# * RUN BEFORE any path mods...
my_loc=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
source "$my_loc/early/path-init.bash"


# TODO decide if/when to set these (i.e. mac vs linux envs...)
# PRN will iterm2 shell integration script setup this if I don't?
# TERM=xterm-256color
if is_macos; then
    # hardcoded version of:
    #   eval $(brew shellenv bash)
    #
    #   another way to approach would be to run this once (in top level shell)
    #     using variable to determine if run when subshells launch...
    #     like I did with path init

    prepend_path "/opt/homebrew/bin"
    prepend_path "/opt/homebrew/sbin"

    export HOMEBREW_PREFIX="/opt/homebrew"
    export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
    export HOMEBREW_REPOSITORY="/opt/homebrew"

    [ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}"
    export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
fi


# * uncomment for xtrace-ing
# export PS1="$ "
# unset PROMPT_COMMAND # remove default for xtrace, when also comment out the return here:
# return

for script in "$my_loc/startup/first/"*.bash; do
    source "$script"
done
source "$my_loc/.generated.aliases.bash"
for script in "$my_loc/startup/"*.bash; do
    source "$script"
done
