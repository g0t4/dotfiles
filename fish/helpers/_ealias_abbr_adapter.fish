
# ealias is a big part of what I use in my dotfiles in terms of zsh customization.... a adapater alone for this would make fish much more usable to test drive it...
function ealias --description "map ealias to fish abbr(eviation)"

    # wow I already like fish scripting way better than zsh/bash!

    if test (count $argv) -eq 0 || test (count $argv) -gt 2
        echo "invalid alias definition:"
        echo "  ealias <aliasname>=<alias_value>"
        echo "  ealias <aliasname> <alias_value>"
        return
    end

    if test (count $argv) -eq 2
        # ealias foo bar
        set aliasname $argv[1]
        set alias_value $argv[2]
        echo "name: $aliasname"
        echo "value: $alias_value"
        abbr -a $aliasname $alias_value
        return
    end

    # ealias foo=bar
    set aliasdef $argv[1]
    # split aliasdef on first = into two parts:
    # 1. the alias name
    # 2. the alias definition
    set aliasname (string split -m 1 = $aliasdef)[1]
    set alias_value (string split -m 1 = $aliasdef)[2]

    echo "name: $aliasname"
    echo "value: $alias_value"

    abbr -a $aliasname $alias_value
end
