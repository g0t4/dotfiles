#
# helpers (idea is always use pbcopy/paste -- see below)
ealias pwdcp="pwd | pbcopy"
ealias wdcp="pwd | pbcopy"

if ! is_macos; then
    # on non-macs make it appear as if pbcopy/paste are available
    alias pbcopy="clipcopy"
    alias pbpaste="clippaste"
    # NOTE alias => not expanding
    #   PRN expand pbcopy/paste? (don't hide shell specific mechanism)
    # omz clipcopy/paste (calls system specific backend: ie pbcopy/paste on mac)

    # avoid alias on mac (not confirmed) but I suspect it could cause infinite loop depending on how clipcopy/paste are implemented to use pbcopy/paste on a mac, so just avoid the possibility

    # FYI I use pbcopy/paste in several other functions/aliases so make sure to consider those if you change how pbcopy/paste work
fi

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
