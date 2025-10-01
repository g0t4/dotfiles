
# TODO test in wsl

# https://learn.microsoft.com/en-us/windows/terminal/tutorials/new-tab-same-directory#fish
function storePathForWindowsTerminal --on-variable PWD
    if test -n "$WT_SESSION"
        printf "\e]9;9;%s\e\\" (wslpath -w "$PWD")
    end
end
