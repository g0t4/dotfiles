# ! KEEP THIS FILE MINIMAL, only critical, early config should be in here

# # * uncomment for xtrace-ing (fyi.. can inherit path from outer shell)
# export PS1="\W $ "
# unset PROMPT_COMMAND # remove default for xtrace, when also comment out the return here:
# return

source "$BASH_DOTFILES/shared.bashrc.sh"

for script in "$BASH_DOTFILES/startup/course-only/"*.bash; do
    source "$script"
done

if is_interactive; then
    # some things to remove for first course, but leave in my full bashrc
    abbr --remove wc
fi
