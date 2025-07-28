#
# *** vi mode
set -o vi
# FYI find differences:
#    icdiff <((set -o vi; bind -p)) <((set -o emacs; bind -p))
#
# FIX self-insert differences
#    icdiff <((set -o vi; bind -p | grep -i self-insert)) <((set -o emacs; bind -p | grep -i self-insert))
#
bind '"\\": self-insert' # missing in vi mode?! found in emacs mode:   bind -p | grep '\\"'
#
# FYI make sure to bind keymaps for vi mode too (-m vi-insert) (-m vi-command)
# choices: emacs, emacs-standard, emacs-meta, emacs-ctlx, vi, vi-move, vi-command, and vi-insert
# also emacs keymaps I like, rebound for vi-insert
bind -m vi-insert '"\e.": yank-last-arg'

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

# * readline variables
abbr bind_current_keymap "bind -v | grep keymap"
abbr bind_list_readline_variables "bind -v" # exec format
abbr bindv "bind -v"


# * key sequences
#
# bind maps key sequences to one of three actions:
# 1. readline function (same as in ~/.inputrc)
# 2. macro (text to insert including further key sequences, same as in ~/.inputrc)
# 3. bash shell function (bash specific, not in ~/.inputrc)
#
abbr binds_all "bind -p; bind -s; bind -X"
#
abbr binds_to_readline_funcs "bind -p"
abbr bindp "bind -p" # readline func key sequences - exec format
#
abbr binds_to_macros "bind -s"
abbr binds "bind -s" # macro key sequences - exec format
#
abbr binds_to_bash_funcs "bind -X"
abbr bindX "bind -X" # list bash func key sequences
abbr bindx "bind -x" # to add key seq. to bash functions
abbr bindx_shell_cmd_colon "bind -x '\"%\": shell_func arg1 arg2'"
# abbr bindx_shell_cmd_whitespace "bind -x \"%\" shell_func arg1 arg2" #
# TODO later format supports backslash-escape expansion (in readline)... is that for args?
#
# list readline funcs:
abbr bindl "bind -l"
abbr bind_list_readline_func_names "bind -l"

# * query key sequence for readline func
abbr bindq "bind -q" # keys mapped to function name:  bind -q yank-last-arg



# keep in mind, longer abbrs are reminder abbrs
