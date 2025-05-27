function pym
    # usage:
    #  pym foo/bar.py
    #
    #  translates to:
    #  python3 -m foo.bar

    # honestly the better fix is to add completion for module names in `python3 -m <TAB>` command
    #   / => .
    #   strip .py on end
    eval (_pym_expand $argv[1])
end
