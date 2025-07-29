#
# *** vi mode
set -o vi
# fix vi-insert vs emacs differences:
#   icdiff <((bind -m vi-insert -p)) <((bind -m emacs -p ))
#
# FIX self-insert differences
#    icdiff <((bind -m vi-insert -p)) <((bind -m emacs -p )) | grep -i self-insert
#    ok and now this isn't an issue... WTH? maybe one of my bindings was wrong when testing and I deleted \\?
# bind -m vi-insert '"\\": self-insert' # missing in vi mode?! found in emacs mode:   bind -p | grep '\\"'

# vi-unix-word-rubout doesn't work inside ""...
#  so just rebind to emacs version?
bind -m vi-insert '"\C-w": unix-word-rubout'
# "\C-w": vi-unix-word-rubout # original binding in vi-insert keymap

#
# FYI make sure to bind keymaps for vi mode too (-m vi-insert) (-m vi-command)
# choices: emacs, emacs-standard, emacs-meta, emacs-ctlx, vi, vi-move, vi-command, and vi-insert
# also emacs keymaps I like, rebound for vi-insert
bind -m vi-insert '"\e.": yank-last-arg'
#
# emacs expand key sequences (no collision with vi-insert mode)
#  that way I can still demo w/ the same defaults
bind -m vi-insert '"\eg": glob-complete-word'
bind -m vi-insert '"\C-x*": glob-expand-word'
bind -m vi-insert '"\e^": history-expand-line'
bind -m vi-insert '"\e\C-e": shell-expand-line'
#  wow shell-expand-line messes up:
#  foo=(a "b c" " " ef)
#  echo "${foo[@]}" # invoke shell-expand-line... doesn't quote the expanded args?!
#  # this is the result, wow:
#  echo a b c   ef
bind -m vi-insert '"\e&": tilde-expand'
#
# maybe adds (unbound by default in emacs):
# alias-expand-line
# history-and-alias-expand-line

# FYI \C-x\C-u is mapped in vi-insert to undo, works good too!

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
abbr bind-current-keymap "bind -v | grep keymap"
abbr bind-list-readline-variables "bind -v" # exec format
abbr bindv "bind -v"


# * key sequences
#
# bind maps key sequences to one of three actions:
# 1. readline function (same as in ~/.inputrc)
# 2. macro (text to insert including further key sequences, same as in ~/.inputrc)
# 3. bash shell function (bash specific, not in ~/.inputrc)
#
abbr binds-all "bind -p; bind -s; bind -X"
#
abbr binds-to-readline-funcs "bind -p"
abbr bindp "bind -p" # readline func key sequences - exec format
abbr bindp_vi_insert "bind -m vi-insert -p"
abbr bindp_vi_command "bind -m vi-command -p"
abbr bindp_emacs "bind -m emacs -p"
#
abbr binds-to-macros "bind -s"
abbr binds "bind -s" # macro key sequences - exec format
#
abbr binds-to-bash-funcs "bind -X"
abbr bindX "bind -X" # list bash func key sequences
abbr bindx "bind -x" # to add key seq. to bash functions
abbr --set-cursor bindx-shell-cmd-colon "bind -x '\"%\": example_bash_func arg1 arg2'"
# abbr --set-cursor bindx-shell-cmd-whitespace "bind -x \"%\" example_bash_func arg1 arg2" #
# TODO later format supports backslash-escape expansion (in readline)... is that for args?
#
# list readline funcs:
abbr bindl "bind -l"
abbr bind_list_readline_func_names "bind -l"

# * query key sequence for readline func
abbr bindq "bind -q" # keys mapped to function name:  bind -q yank-last-arg



# keep in mind, longer abbrs are reminder abbrs
