
# make it appear as if pbcopy/paste are available
# assumption: this only runs on windows+pwsh
ealias pbcopy "Set-Clipboard" # macos equiv
ealias pbpaste "Get-Clipboard" # macos equiv
ealias pwdcp "pwd | Set-Clipboard" # expand to pwsh equivalent
ealias wdcp "pwd | Set-Clipboard" # expand to pwsh equivalent
# FYI look at clipcopy/paste in omz, or fish_*_copy/paste for how other tools wrap system specific backends (ie to make pbcopy/paste an entrypoint in pwsh+win)

