

function _find_local_config
    set -l dir (pwd)
    while test $dir != /
        if test -f $dir/config.fish
            echo $dir/config.fish
            return
        end
        set dir (dirname $dir)
    end
end

function _load_local_config
    set -l config_path (_find_local_config)
    if test -z "$config_path"
        return
    end

    # deactivate previous local config if it exists
    if functions -q deactivate_local_config_fish
        deactivate_local_config_fish
    end

    # source the new config
    source $config_path

    # ensure the new config defined deactivate_local_config_fish
    if not functions -q deactivate_local_config_fish
        function deactivate_local_config_fish
            # no-op placeholder
        end
    end
end

# Hook into directory changes
if not functions -q __fish_cd_hook_local_config
    function __fish_cd_hook_local_config --on-variable PWD
        _load_local_config
    end
end

# also load when starting a new session
_load_local_config


