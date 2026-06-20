
function __fish_ansible-lint_complete
    set -lx _ARGCOMPLETE 1
    set -lx _ARGCOMPLETE_DFS \t
    set -lx _ARGCOMPLETE_IFS \n
    set -lx _ARGCOMPLETE_SUPPRESS_SPACE 1
    set -lx _ARGCOMPLETE_SHELL fish
    set -lx COMP_LINE (commandline -p)
    set -lx COMP_POINT (string length (commandline -cp))
    set -lx COMP_TYPE
    if set -q _ARC_DEBUG
        ansible-lint 8>&1 9>&2 1>&9 2>&1
    else
        ansible-lint 8>&1 9>&2 1>/dev/null 2>&1
    end
end
complete --command ansible-lint -f -a '(__fish_ansible-lint_complete)'
