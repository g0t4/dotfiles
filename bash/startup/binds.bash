#
# *** vi mode
set -o vi
# FYI make sure to bind keymaps for vi mode too (-m vi-insert) (-m vi-command)
# choices: emacs, emacs-standard, emacs-meta, emacs-ctlx, vi, vi-move, vi-command, and vi-insert

# *** custom yank

copy_and_clear_line() {
    # current line only, FYI in vi mode you can use `yy` or `dd` to copy/nuke entire line
    echo -n "$READLINE_LINE" | pbcopy
    READLINE_LINE=
}

bind -x '"\ek": copy_and_clear_line'
bind -m vi-insert -x '"\ek": copy_and_clear_line'
# FYI I should be using yy/dd in vi mode... but I am going to leave Esc-k too just to have it be consistent...
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
