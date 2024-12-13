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
        echo "brew list: $(brew list | xargs echo)"
        echo
    end
end
