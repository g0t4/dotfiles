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

function _auto_venv_find_venv_in_or_above_dir --argument-names dir_absolute_path
    # Assume dir_absolute_path is absolute, given we start with $PWD
    # FYI if needed to get absolute path, then use
    #     set dir_absolute_path (path resolve $dir_absolute_path)

    # to understand how this works, uncomment: (and cd around filesystem)
    # echo "searching for venv in $dir_absolute_path" >&2 # print to stderr so not captured if using cmd substitution

    if test -e "$dir_absolute_path/.venv.local"
        echo "$dir_absolute_path/.venv.local"
        return 0
    else if test -e "$dir_absolute_path/.venv"
        echo "$dir_absolute_path/.venv"
        return 0
    end

    if test "$dir_absolute_path" = /
        # stop at root of filesystem => /
        # another option might be to stop at root of repo (if in a repo)
        return 1
    end

    set -l parent_dir (path dirname "$dir_absolute_path")
    _auto_venv_find_venv_in_or_above_dir "$parent_dir"
    return $status
end

function _auto_venv_pwd_changed_handler --on-variable PWD
    set venv_dir (_auto_venv_find_venv_in_or_above_dir "$PWD")

    if test $status -ne 0
        # no venv found
        if test -n "$VIRTUAL_ENV"
            # it is possible to inherit VIRTUAL_ENV env var but not have actually activated the venv in the new shell process, hence check for deactivate before trying to use it!
            #  splitting a new pane in iTerm from a pane with an activate venv => IIRC I copy venv in this case and hence bug with deactivate not being defined and yet called
            if functions -q deactivate
                deactivate
            end
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

# * auto nvm use

# PRN could skip registering the PWD change handler if nvm not in path

function find_upward --argument-names filename start_dir
    if test -z "$start_dir"
        set start_dir $PWD
    end

    set -l dir (path resolve "$start_dir")

    while true
        set -l candidate "$dir/$filename"

        if test -e "$candidate"
            echo "$candidate"
            return 0
        end

        set -l parent (path dirname "$dir")

        if test "$parent" = "$dir"
            return 1
        end

        set dir "$parent"
    end
end

function __auto_nvm_use --on-variable PWD

    set -l nvmrc (find_upward .nvmrc)

    if test -n "$nvmrc"
        set -l requested_node_version (string trim <"$nvmrc")

        # FYI if `nvm current` is ever slow then find a better way to evaluate if current version is requested
        # with fish shell nvm functions, # FYI if `nvm current` is fast (path lookup + query)
        if test (nvm current) != "$requested_node_version"
            nvm use "$requested_node_version" >/dev/null
        end
    else
        # no .nvmrc => use system version of node
        if test (nvm current) != system
            nvm use system >/dev/null
        end
    end

end

__auto_nvm_use
