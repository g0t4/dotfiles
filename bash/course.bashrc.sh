[[ -n "$WES_TRACE_STARTUP" ]] && (IFS="<" echo "sourcing ${BASH_SOURCE[*]}")

# # * uncomment for xtrace-ing (fyi.. can inherit path from outer shell)
# export PS1="\W $ "
# unset PROMPT_COMMAND # remove default for xtrace, when also comment out the return here:
# return

source "$BASH_DOTFILES/shared.bashrc.sh"

source "$BASH_DOTFILES/.generated.paredabbrs.bash"

for script in "$BASH_DOTFILES/startup/course-only/"*.bash; do
    source "$script"
done
