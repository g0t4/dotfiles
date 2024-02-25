# FYI: ~/.zprofile has some brew init too (brew shellenv)
# PRN mac only and wes/weshigbee user?

export HOMEBREW_BAT=1 # for `brew cat` command, must export for brew's child process to use this
# https://github.com/Homebrew/brew/blob/master/Library/Homebrew/env_config.rb

############## readonly actions (ok to do with any user account)
abbr bcat 'brew cat'
abbr bd 'brew doctor --quiet' # --quiet suppresses output if successful
abbr bh 'brew home'  # i.e. brew home bat
abbr bi 'brew info'
abbr big 'brew info --github'
abbr bl 'brew list'
abbr blc 'brew list --cask'
abbr blf 'brew list --formula'
abbr bo 'brew outdated' # compliments bubo (update/outdated)
abbr bp 'brew --prefix'
# abbr bs 'brew search' # fish has bs impl that uses analytics, not yet porting that to zsh so for now just get rid of what would otherwise become a duplicated alias in fish AND... this is a reminder to port to zsh if I ever find myself wanting it there
abbr bsvc 'brew services' # list state of brew installed services (daemons)

abbr bus 'brew uses --eval-all' # ... depends on X
abbr bde 'brew deps' # X depends on ...

abbr bar 'brew autoremove'
abbr bcl 'brew cleanup'

abbr bin 'brew install'
# abbr binv 'brew install --verbose --debug'

abbr bup 'brew upgrade'
abbr bubc 'brew upgrade && brew cleanup' # src: omz/brew
abbr bubo 'brew update && brew outdated' # src: omz/brew
abbr bubu 'bubo && bubc' # src: omz/brew

abbr bun 'brew uninstall'
