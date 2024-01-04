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
