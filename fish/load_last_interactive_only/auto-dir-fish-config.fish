
# *** features:
# Parent-dir walk for first .config.fish
# Guard against re-loading on nested cd
# Single active config at a time with teardown before load
# Snapshot before/after source, only cleanup what was added by .config.fish
# `--on-variable PWD` fish-native trigger

function _find_local_config
    set -l dir (pwd)
    while test "$dir" != /
        if test -f "$dir/.config.fish"
            echo "$dir/.config.fish"
            return
        end
        set dir (dirname "$dir")
    end
end

function __local_config_load_inner

    set -l current_local_config_path (_find_local_config)
    if set -q __last_local_config_path; and test "$__last_local_config_path" = "$current_local_config_path"
        # echo "already loaded the same config, nothing to do"
        return
    end
    # echo "current: $current_local_config_path"

    if functions -q deactivate_last_local_config
        deactivate_last_local_config
    end

    if test -z "$current_local_config_path"
        # echo "no local .config.fish, nothing to do"
        return
    end

    set --global __local_config_funcs_before (functions -n)
    set --global __local_config_abbrs_before (abbr --list)

    source "$current_local_config_path"
    set --global __last_local_config_path "$current_local_config_path"

    set --global __local_config_funcs_after (functions -n)
    set --global __local_config_abbrs_after (abbr --list)

    function deactivate_last_local_config

        # comm needed for performance (hitting about 30-40ms total which sucks but it only happens on cd and only when leaving the scope of a .config.fish)
        set -f abbrs_added (comm -1 -3 (printf '%s\n' $__local_config_abbrs_before | sort | psub) (printf '%s\n' $__local_config_abbrs_after | sort | psub))
        set -f funcs_added (comm -1 -3 (printf '%s\n' $__local_config_funcs_before | sort | psub) (printf '%s\n' $__local_config_funcs_after | sort | psub))

        # echo
        # echo removing abbrs: $abbrs_added
        # echo removing funcs: $funcs_added

        functions --erase $funcs_added
        abbr --erase $abbrs_added

        set -e __local_config_funcs_before __local_config_abbrs_before __local_config_funcs_after __local_config_abbrs_after __last_local_config_path
        functions -e deactivate_last_local_config
    end
end

function __local_config_load --on-variable PWD
    # time __local_config_load_inner
    __local_config_load_inner
end

# run during startup if initial PWD has a local .config.fish
__local_config_load
