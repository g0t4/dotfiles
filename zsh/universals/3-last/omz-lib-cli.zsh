


function _reload_like_omz {
  # Delete current completion cache
  command rm -rf ~/.zcomp* # for now just nuke all ~/.zcomp files/dirs => ~/.zcompdump seems default now and also ~/.zcompcache shows up at times
  # command rm -f $_comp_dumpfile $ZSH_COMPDUMP

  # ! IS THIS NECESSARY? wes added this
  hash -r # clear previously hashed commands/funcs/etc

  # determine shell options (ie interactive/login)... though why would I reload in a non-interactive shell?
  # Old zsh versions don't have ZSH_ARGZERO
  local zsh="${ZSH_ARGZERO:-${functrace[-1]%:*}}"
  # Check whether to run a login shell
  [[ "$zsh" = -* || -o login ]] && exec -l "${zsh#-}" || exec "$zsh"
}

#! todo rest of lib/cli.zsh from OMZ? do I want any of it?