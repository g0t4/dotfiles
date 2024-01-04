## TODOs
#    - omz clipcopy/paste (make public)

#
# helpers (idea is always use pbcopy/paste -- see below)
ealias pwdcp="pwd | pbcopy"
ealias wdcp="pwd | pbcopy"

# alias pbcopy/paste (muscle memory for me)
alias pbcopy="clipcopy" # from omz => works
alias pbpaste="clippaste"
# PRN expand pbcopy/paste? (don't hide shell specific mechanism)
# omz clipcopy/paste (calls system specific backend: ie pbcopy/paste on mac)
