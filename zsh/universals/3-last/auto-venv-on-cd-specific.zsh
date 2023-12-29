function _auto_venv_find_venv_in_or_above_dir() {

  _dir=$1
  if [[ -e "${_dir}/.venv.local" ]]; then
    echo "${_dir}/.venv.local"
    return 0
  elif [[ -e "${_dir}/.venv" ]]; then
    echo "${_dir}/.venv"
    return 0
  fi

  _parent_dir=$(dirname "${_dir}")
  if [[ "${_parent_dir}" == "${_dir}" ]]; then
    # top of hierarchy => /
    return 1
  fi

  _auto_venv_find_venv_in_or_above_dir "${_parent_dir}"
  if [[ $? -ne 0 ]]; then
    return 1
  fi

  return 0
}

function _auto_venv_chpwd_handler() {
  # FYI: https://zsh.sourceforge.io/Doc/Release/Functions.html#Hook-Functions
  #   and https://zsh.sourceforge.io/Doc/Release/User-Contributions.html#Manipulating-Hook-Functions

  current_dir=$PWD
  venv_dir=$(_auto_venv_find_venv_in_or_above_dir "${current_dir}")
  if [[ $? -ne 0 ]]; then
    if [[ -n "${VIRTUAL_ENV}" ]]; then
      deactivate
    fi
    return 0
  fi

  # activate it (appears idempotent so just run it every time)
  _activate="${venv_dir}/bin/activate"
  if [[ ! -e "${_activate}" ]]; then
    log_error "Missing venv activate script:\n  ${_activate}"
    return
  fi
  source "${_activate}"
  if [[ $? -ne 0 ]]; then
    log_error "activate failed!!!!"
  fi

}

# register hook
autoload -U add-zsh-hook
add-zsh-hook chpwd _auto_venv_chpwd_handler

# run during startup to activate venv if in one now
_auto_venv_chpwd_handler
