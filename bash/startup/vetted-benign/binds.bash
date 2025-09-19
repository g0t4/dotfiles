if ! is_interactive; then
    return
fi
# *** custom yank

copy_and_clear_line() {
    # current line only, FYI in vi mode you can use `yy` or `dd` to copy/nuke entire line
    echo -n "$READLINE_LINE" | fish -c pbcopy
    READLINE_LINE=
}

bind -m emacs -x '"\ek": copy_and_clear_line'
bind -m vi-insert -x '"\ek": copy_and_clear_line'
bind -m vi-command -x '"\ek": copy_and_clear_line'
# FYI I should be using yy/dd in vi mode... but I am going to leave Esc-k too just to have it be consistent...
# FYI use \C-k for Ctrl-k vs \ek for Esc-k ... cannot do: \Ck nor \e-k
