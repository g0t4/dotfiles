#
# *** vi mode
set -o vi
# TODO! later I am having trouble remapping \C-w unix-word-rubout below
#   vi-unix-word-rubout doesn't work inside "" like
#   git commit -m "foo the bar<CURSOR><Ctrl-W>" # should remove words inside...
#      by the way it only doesn't work if cursor is on char right before end of string (before ending ")
#   I swear a few times I got this to work
#   but I cannot reproduce it... maybe I am confusing ctrl-w outside "" which does work
#   anyways I need to use emacs mode for course anyways so leave this for later
#   TODO is it not possible to override readline key sequences?
#
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
bind -m vi-command '"\C-w": unix-word-rubout'
# TODO why isn't this working in vi-insert mode?
# "\C-w": vi-unix-word-rubout # original binding in vi-insert keymap

# up/down arrows (some of this is from my ~/.inputrc, to mirror it in vi mode)
bind -m vi-insert '"\e[A": history-substring-search-backward'
bind -m vi-insert '"\e[B": history-substring-search-forward'
bind -m vi-command '"\e[A": history-substring-search-backward'
bind -m vi-command '"\e[B": history-substring-search-forward'
# PRN map emacs here just in case?


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

bind -m emacs -x '"\ek": copy_and_clear_line'
bind -m vi-insert -x '"\ek": copy_and_clear_line'
bind -m vi-command -x '"\ek": copy_and_clear_line'
# FYI I should be using yy/dd in vi mode... but I am going to leave Esc-k too just to have it be consistent...
# FYI use \C-k for Ctrl-k vs \ek for Esc-k ... cannot do: \Ck nor \e-k

# *** bind
_abbrs_bind() {
    # syntax highlight bind mappings
    local bind_bat="| bat -l yaml"
    # FYI chose yaml b/c it highlights escape sequences which are key in keymaps!

    # * readline variables
    abbr bind-current-keymap "bind -v | grep keymap"
    abbr bind-list-readline-variables "bind -v $bind_bat" # exec format
    abbr bindv "bind -v $bind_bat"
    abbr bind_show_mode 'bind "set show-mode-in-prompt on"'

    # * key sequences
    #
    # bind maps key sequences to one of three actions:
    # 1. readline function (same as in ~/.inputrc)
    # 2. macro (text to insert including further key sequences, same as in ~/.inputrc)
    # 3. bash shell function (bash specific, not in ~/.inputrc)
    #
    abbr bind-all "bind -psX "
    abbr bindviins-all "bind -m vi-insert -psX $bind_bat"
    abbr bindvicmd-all "bind -m vi-command -psX $bind_bat"
    abbr bindemacs-all "bind -m emacs -psX $bind_bat"
    #
    abbr bind-to-readline-funcs "bind -p $bind_bat"
    abbr bindp "bind -p $bind_bat" # readline func key sequences - exec format
    #
    abbr bind-to-macros "bind -s $bind_bat"
    abbr binds "bind -s $bind_bat" # macro key sequences - exec format
    #
    abbr bind-to-bash-funcs "bind -X $bind_bat"
    abbr bindX "bind -X $bind_bat" # list bash func key sequences
    abbr bindx "bind -x $bind_bat" # to add key seq. to bash functions
    #
    # list readline funcs:
    abbr bindl "bind -l"
    abbr bind-list-readline-func-names "bind -l"

    # * query key sequence for readline func
    abbr bindq "bind -q" # keys mapped to function name:  bind -q yank-last-arg

}
_abbrs_bind
