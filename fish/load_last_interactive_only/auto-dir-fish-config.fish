function _find_local_config
    set -l dir (pwd)
    while test $dir != /
        if test -f $dir/.config.fish
            echo $dir/.config.fish
            return
        end
        set dir (dirname $dir)
    end
end

function _load_local_config --on-variable PWD

    if functions -q deactivate_local_config_fish
        deactivate_local_config_fish
        functions --erase deactivate_local_config_fish
    end

    set -l local_config_path (_find_local_config)
    if test -z "$local_config_path"
        return
    end

    source $local_config_path

    if not functions -q deactivate_local_config_fish
        function deactivate_local_config_fish
            # no-op placeholder
        end
    end
end

# run during startup if initial PWD has a local .config.fish
_load_local_config
