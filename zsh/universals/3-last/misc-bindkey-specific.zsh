_custom_kill_and_copy_buffer() {
    # clears line and puts it into clipboard (also yank goes to killring)
    zle kill-buffer
    echo -n $CUTBUFFER | pbcopy
}

zle -N _custom_kill_and_copy_buffer

# use meta/esc+k - since ctrl+k is kill alone
bindkey '\ek' _custom_kill_and_copy_buffer
