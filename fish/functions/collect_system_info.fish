function collect_system_info
    set -l os (uname)
    set -l os_version (sw_vers -productVersion 2>/dev/null || echo "N/A")
    set -l arch (uname -m)
    set -l shell_version $FISH_VERSION
    set -l git_version (git --version | cut -d" " -f3)
    set -l python3_version (python3 --version 2>/dev/null || echo "N/A")
    set -l brew_version (brew --version 2>/dev/null | head -n1 | cut -d" " -f2 || echo "N/A")
    
    printf "%s\n" \
        "OS: $os $os_version" \
        "Architecture: $arch" \
        "Shell: fish $shell_version" \
        "Git: $git_version" \
        "Python3: $python3_version" \
        "Homebrew: $brew_version"
end
