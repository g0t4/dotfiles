( IFS="<"; echo "sourcing ${BASH_SOURCE[*]}")


UNAME_S=$(uname -s)
is_macos() {
    [[ "$UNAME_S" = "Darwin" ]]
}

# * ensure path is consistenly setup regardless if login shell or not
#  normally this is only run in /etc/profile for login shells
#  I'd prefer I handle it here and just cache when it was run with an env var
if is_macos && [[ -z "$__PATH_HELPER_RAN" ]]; then
  eval "$(/usr/libexec/path_helper -s)"
  export __PATH_HELPER_RAN=1
fi

# resolve path to this script so I can import others nearby
my_loc=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

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
