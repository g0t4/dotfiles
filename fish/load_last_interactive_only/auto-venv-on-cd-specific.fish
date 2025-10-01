# ************************************************************************
# ******  !! 2025-01-06 DISABLED because THANKS TO uv I don't need this anymore... I will leave it around a bit longer just in case but dang...
# ******  b/c these don't require venv activation:
# ******    `uv pip list`
# ******    `uv add foo`
# ******    `uv run x.py`
# ******    IIRC these are the only things I did that needed to activate a venv
# ******    FYI any scripts that also call activate.fish directly... or that path to python in the venv... also work (don't need to be ported to uv run)
# ************************************************************************
# ************************************************************************
# ************************************************************************
#  FYI this takes 7ms+ to run on every startup!

if not status is-interactive
    # do not use autovenv in non-interactive shells (ie scripts)
    return
end

# PRN register / run as late as possible, else PATH changes after this are reverted on deactive


# disable modifying the fish prompt (I will modify it myself to prepend python icon)
set -gx VIRTUAL_ENV_DISABLE_PROMPT true

function _auto_venv_find_venv_in_or_above_dir

    set -l _dir (realpath $argv[1]) # realpath => absolute path (i.e. to demo what this func does => call w/ relative path)

    # to understand how this works, uncomment: (and cd around filesystem)
    # echo "searching for venv in $_dir" >&2 # print to stderr so not captured if using cmd substitution

    if test -e "$_dir/.venv.local"
        echo "$_dir/.venv.local"
        return 0
    else if test -e "$_dir/.venv"
        echo "$_dir/.venv"
        return 0
    end

    if test "$_dir" = /
        # stop at root of filesystem => /
        # another option might be to stop at root of repo (if in a repo)
        return 1
    end

    set -l _parent_dir (dirname "$_dir")
    _auto_venv_find_venv_in_or_above_dir "$_parent_dir"
    return $status
end

function _auto_venv_pwd_changed_handler --on-variable PWD
    set venv_dir (_auto_venv_find_venv_in_or_above_dir "$PWD")

    if test $status -ne 0
        # no venv found
        if test -n "$VIRTUAL_ENV"
            deactivate
        end
        return 0
    end

    # venv found => activate it (idempotent, run it every time)
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

# run during startup to activate venv if initial PWD is in a venv
_auto_venv_pwd_changed_handler
