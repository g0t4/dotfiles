
# helpers (idea is always use pbcopy/paste -- see below)
ealias pwdcp="pwd | pbcopy"
ealias wdcp="pwd | pbcopy"

# alias pbcopy/paste (muscle memory for me)
alias pbcopy="fish_clipboard_copy"
alias pbpaste="fish_clipboard_paste"
# NOTE fish alias == function (its not expanding)
#   PRN expand pbcopy/paste? (don't hide shell specific mechanism)
# fish_*_copy/paste call system specific backend (just like omz's clipcopy/clippaste)
# PRN - if I have issues using these aliases to fish_*_copy/paste on a mac then I can skip these aliases on macs and go back to directly using pbcopy/paste