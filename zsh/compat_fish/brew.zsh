# FYI: ~/.zprofile has some brew init too (brew shellenv)
# PRN mac only and wes/weshigbee user?

export HOMEBREW_BAT=1 # for `brew cat` command, must export for brew's child process to use this
# https://github.com/Homebrew/brew/blob/master/Library/Homebrew/env_config.rb

############## readonly actions (ok to do with any user account)
ealias bcat='brew cat'
ealias bd='brew doctor --quiet' # --quiet suppresses output if successful
ealias bh='brew home'  # i.e. brew home bat
ealias bi='brew info'
ealias big='brew info --github'
ealias bl='brew list'
ealias blc='brew list --cask'
ealias blf='brew list --formula'
ealias bo='brew outdated' # compliments bubo (update/outdated)
ealias bp='brew --prefix'
ealias bs='brew search'
ealias bsvc='brew services' # list state of brew installed services (daemons)

ealias bus='brew uses --eval-all' # ... depends on X
ealias bde='brew deps' # X depends on ...

ealias bar='brew autoremove'
ealias bcl='brew cleanup'

ealias bin='brew install'
# ealias binv='brew install --verbose --debug'

ealias bup='brew upgrade'
ealias bubc='brew upgrade && brew cleanup' # src: omz/brew
ealias bubo='brew update && brew outdated' # src: omz/brew
ealias bubu='bubo && bubc' # src: omz/brew

ealias bun='brew uninstall'
