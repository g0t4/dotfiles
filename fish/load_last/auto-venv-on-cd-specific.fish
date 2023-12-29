
# disable modifying the fish prompt (I will modify it myself to prepend python icon)
set -gx VIRTUAL_ENV_DISABLE_PROMPT true

function _auto_venv_find_venv_in_or_above_dir

  set -l _dir $argv[1]
  if test -e "$_dir/.venv.local"
    echo "$_dir/.venv.local"
    return 0
  else if test -e "$_dir/.venv"
    echo "$_dir/.venv"
    return 0
  end

  set -l _parent_dir (dirname "$_dir")
  if test "$_parent_dir" = "$_dir"
    # top of hierarchy => /
    return 1
  end

  _auto_venv_find_venv_in_or_above_dir "$_parent_dir"
  # * $status (exit code) works in both zsh/fish
  if test $status -ne 0
    return 1
  end

  return 0
end

function _auto_venv_chpwd_handler --on-variable PWD
  set current_dir $PWD
  set venv_dir (_auto_venv_find_venv_in_or_above_dir "$current_dir")
  if test $status -ne 0
    if test -n "$VIRTUAL_ENV"
      deactivate
    end
    return 0
  end

  # activate it (appears idempotent so just run it every time)
  set _activate "$venv_dir/bin/activate.fish"
  if not test -e "$_activate"
    echo "Missing venv activate script:\n  $_activate"
    return
  end
  . "$_activate"
  if test $status -ne 0
    echo "activate failed!!!!"
  end
end

# run during startup to activate venv if in one now
_auto_venv_chpwd_handler
