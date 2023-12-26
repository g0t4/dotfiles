#
# *** FYI due to command substitution and history expansion differences, this is currently only applicable to zsh (not fish)

# icdiff
# PRN export ICDIFF_OPTIONS="--highlight" # FYI highlight is not an automatically wise idea to use, it loses some of value of icdiff (I do like it for ffmpeg and mediainfo output that is often very similar except for a few fields, so then the background color stands out much more than text color alone... might indicate I shouldn't use yellow for white too ;)  )
ealias ic="icdiff -H"
ealias icr="icdiff --recursive" # diff all files in two dirs
ealias icg="git-icdiff"
# configure git-icdiff via git config: git config --global icdiff.options '--line-numbers'
# thanks to expanding alises + zsh param expansion => it's clear what will happen (ie commands will be re-run)... essentially saves copy/paste previous two commands into icdiff <(cmd1) <(cmd2) format"
# - i.e. `echo foo` then `echo bar` results in: `icdiff <(echo foo) <(echo foobar)`
ealias diff_last_two_commands='icdiff -L "!-2" <(!-2) -L "!-1" <(!-1)' # * favorite
ealias diff_last_two_commandsEQUALS='icdiff -L "!-2" =(!-2) -L "!-1" =(!-1)'
