#
# helpers (idea is always use pbcopy/paste -- see below)
ealias pwdcp="pwd | pbcopy"
ealias wdcp="pwd | pbcopy"

# alias pbcopy/paste (muscle memory for me)
alias pbcopy="clipcopy" # from omz => works
alias pbpaste="clippaste"
# NOTE alias => not expanding
#   PRN expand pbcopy/paste? (don't hide shell specific mechanism)
# omz clipcopy/paste (calls system specific backend: ie pbcopy/paste on mac)
# PRN - if I have issues using these aliases to clipcopy/paste on a mac then I can skip these aliases on macs and go back to directly using pbcopy/paste

# *** yank+copy binding: meta/esc+k
_custom_kill_and_copy_buffer() {
    # clears line and puts it into clipboard (also yank goes to killring)
    zle kill-buffer
    echo -n $CUTBUFFER | clipcopy
    # CONFIRMED clipcopy works here on a mac
    # TODO TEST clipcopy works here in WSL
}

zle -N _custom_kill_and_copy_buffer

# use meta/esc+k - since ctrl+k is kill alone
bindkey '\ek' _custom_kill_and_copy_buffer
