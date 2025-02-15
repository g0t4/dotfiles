function collect_system_info
    if $IS_MACOS
        uname -smv # -v = os version, -m = arch, -s = os name
        #set -l os_version (sw_vers -productVersion 2>/dev/null || echo "N/A")
    else if $IS_LINUX
        cat /etc/os-release | grep PRETTY_NAME
        uname -m
    end
    echo "hostname: $(hostname)"

    if command -q brew
        echo "brew --prefix: $(brew --prefix)"
        # TODO would be nice to filter noise, to trucnate somehow... i.e. bat-extras-batdiff... maybe find the commands themselves and not the formula/cask names?
        # PERHAPS filter the list with known important commands (i.e. ag command, gcoreutils set, etc that will help write commands and I could add to this list as I encounter issues without it)
        echo "brew list: $(brew list | xargs echo)"
        echo
        # considering mentioning these (if avail):
        #    ag python3 nvim fish zsh rg fd gh eza
        # these I feel should be assumed always avail (not sure these all should be told to claude though):
        #    git docker curl wget nmap bat
        #  maybe also assumed:
        #    bat kubectl minikube node go rust
        #
    end
end
