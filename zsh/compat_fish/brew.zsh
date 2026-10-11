# FYI: ~/.zprofile has some brew init too (brew shellenv)
# PRN mac only and wes/weshigbee user?

export HOMEBREW_BAT=1 # for `brew cat` command, must export for brew's child process to use this
# https://github.com/Homebrew/brew/blob/master/Library/Homebrew/env_config.rb

############## readonly actions (ok to do with any user account)
abbr bcat 'brew as-brew-user cat'
abbr bd 'brew as-brew-user doctor --quiet' # --quiet suppresses output if successful
abbr bh 'brew as-brew-user home'  # i.e. brew home bat
abbr bi 'brew as-brew-user info'
abbr big 'brew as-brew-user info --github'
abbr bl 'brew as-brew-user list'
abbr blc 'brew as-brew-user list --cask'
abbr blf 'brew as-brew-user list --formula'
abbr bo 'brew as-brew-user outdated' # compliments bubo (update/outdated)
abbr bp 'brew as-brew-user --prefix'
# abbr bs 'brew as-brew-user search' # fish has bs impl that uses analytics, not yet porting that to zsh so for now just get rid of what would otherwise become a duplicated alias in fish AND... this is a reminder to port to zsh if I ever find myself wanting it there
abbr bsvc 'brew as-brew-user services' # list state of brew installed services (daemons)

abbr bus 'brew as-brew-user uses --installed _this_pkg_' # ... ? depends on _pkg_
abbr bde 'brew as-brew-user deps _of_this_pkg_' # _this_pkg_ depends on ...
abbr brew_leaves_installed_manually 'brew as-brew-user leaves --installed-on-request' # leaves that I explicitly asked to install
abbr brew_leaves_dangling_deps 'brew as-brew-user leaves --installed-as-dependency' # leaves that I didn't explicitly install... IOTW left overs from other packages I've since removed

abbr bar 'brew as-brew-user autoremove'
abbr bcl 'brew as-brew-user cleanup'

abbr bin 'brew as-brew-user install'
# abbr binv 'brew as-brew-user install --verbose --debug'

abbr bup 'brew as-brew-user upgrade'
abbr bubo 'brew as-brew-user update && brew as-brew-user outdated' # src: omz/brew
abbr bubc 'brew as-brew-user upgrade && brew as-brew-user cleanup' # src: omz/brew
# don't run as any other user but wes (fux up brew installs)
abbr bubu 'test $USER = "wes" && brew as-brew-user update && brew as-brew-user outdated && brew as-brew-user upgrade && brew as-brew-user cleanup' # src: omz/brew

abbr bun 'brew as-brew-user uninstall'
