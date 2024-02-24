# FYI: ~/.zprofile has some brew init too (brew shellenv)
# PRN mac only and wes/weshigbee user?

export HOMEBREW_BAT=1 # for `brew cat` command, must export for brew's child process to use this
# https://github.com/Homebrew/brew/blob/master/Library/Homebrew/env_config.rb

############## readonly actions (ok to do with any user account)
eabbr bcat 'brew cat'
eabbr bd 'brew doctor --quiet' # --quiet suppresses output if successful
eabbr bh 'brew home'  # i.e. brew home bat
eabbr bi 'brew info'
eabbr big 'brew info --github'
eabbr bl 'brew list'
eabbr blc 'brew list --cask'
eabbr blf 'brew list --formula'
eabbr bo 'brew outdated' # compliments bubo (update/outdated)
eabbr bp 'brew --prefix'
# eabbr bs 'brew search' # fish has bs impl that uses analytics, not yet porting that to zsh so for now just get rid of what would otherwise become a duplicated alias in fish AND... this is a reminder to port to zsh if I ever find myself wanting it there
eabbr bsvc 'brew services' # list state of brew installed services (daemons)

eabbr bus 'brew uses --eval-all' # ... depends on X
eabbr bde 'brew deps' # X depends on ...

eabbr bar 'brew autoremove'
eabbr bcl 'brew cleanup'

eabbr bin 'brew install'
# eabbr binv 'brew install --verbose --debug'

eabbr bup 'brew upgrade'
eabbr bubc 'brew upgrade && brew cleanup' # src: omz/brew
eabbr bubo 'brew update && brew outdated' # src: omz/brew
eabbr bubu 'bubo && bubc' # src: omz/brew

eabbr bun 'brew uninstall'
