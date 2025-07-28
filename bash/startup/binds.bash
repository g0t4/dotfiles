copy_and_clear_line() {
    # current line only
    echo -n "$READLINE_LINE" | pbcopy
    READLINE_LINE=
}

bind -x '"\ek": copy_and_clear_line'
# FYI use \C-k for Ctrl-k vs \ek for Esc-k ... cannot do: \Ck nor \e-k

# *** bind

# bind reminder abbrs:
#  "reminder" abbrs b/c they help quickly find commands/options I forgot about
#  tab complete shows these bind_<TAB> => pick one => expands!
abbr bind_list_all "bind -p; bind -s; bind -X"
abbr bind_list_macros "bind -s"
#
abbr bind_list_bash_funcs "bind -X"
# TODO bind -x doesn't work to give executable format... is there another way to match -s/-p (little s/p) ... -S/-P/-X are all "human readable" ... why isn't there an exec format for -X?!
