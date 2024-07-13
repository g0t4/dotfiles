ealias ghrc=gh_repo_create_private
function gh_repo_create_private() {
  local __repo_name="$@"
  if [[ -z "${__repo_name}" ]]; then
    log_error "No repo name provided, aborting..."
    return -1
  fi
  # my convention is to prefix repo name w/ private- => esp b/c I often have corresponding public repos (ie for courses) and this makes it easier to find the private one or public one
  if [[ "$__repo_name" != private-* ]]; then
    __repo_name="private-${__repo_name}"
  fi

  gh repo create --private $__repo_name
  if [[ $? -ne 0 ]]; then
    log_error "Failed to create repo ${__repo_name}, aborting..."
    return -1
  fi

  wcl $__repo_name # clones it, add
  if [[ $? -ne 0 ]]; then
    log_error "Failed to 'wcl ${__repo_name}', aborting..."
    return -1
  fi

  z $__repo_name # change to it
  if [[ $? -ne 0 ]]; then
    log_error "Failed to 'z ${__repo_name}', aborting..."
    return -1
  fi

  commit_gitignores_for  macos linux windows archives images video vim

  fish -c "__z_add" # FYI must be in directory to add (__z_add doesn't take a path)
  # don't care if fails to add to z in fish
}

ealias ghrcp=gh_repo_create_public
function gh_repo_create_public() {
  local __repo_name="$@"
  if [[ -z "${__repo_name}" ]]; then
    log_error "No repo name provided, aborting..."
    return -1
  fi

  gh repo create --public $__repo_name
  if [[ $? -ne 0 ]]; then
    log_error "Failed to create repo ${__repo_name}, aborting..."
    return -1
  fi

  wcl $__repo_name # clones it, add
  if [[ $? -ne 0 ]]; then
    log_error "Failed to 'wcl ${__repo_name}', aborting..."
    return -1
  fi

  z $__repo_name # change to it
  if [[ $? -ne 0 ]]; then
    log_error "Failed to 'z ${__repo_name}', aborting..."
    return -1
  fi

  commit_gitignores_for  macos linux windows archives images video vim

  fish -c "__z_add" # FYI must be in directory to add (__z_add doesn't take a path)
  # don't care if fails to add to z in fish
}
