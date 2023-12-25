
# ealias is a big part of what I use in my dotfiles in terms of zsh customization.... a adapater alone for this would make fish much more usable to test drive it...
function ealias --description "map ealias to fish abbr(eviation)"

    # wow I already like fish scripting way better than zsh/bash!

    set --local options (fish_opt --short=g) # explicit arg specs! ==> same as 'g' but this is clear
    argparse $options -- $argv # removes matching specs from $argv
    # PRN warn on -NoSpaceAfter? don't impl this just warn so I know to custom rewrite it for fish

    if test (count $argv) -eq 0 || test (count $argv) -gt 2
        echo "invalid alias definition:"
        echo "  ealias <aliasname>=<alias_value>"
        echo "  ealias <aliasname> <alias_value>"
        return
    end

    # PRN use argparse on positionals?
    if test (count $argv) -eq 2
        # ealias foo bar
        set aliasname $argv[1]
        set alias_value $argv[2]
    else
        # ealias foo=bar
        set aliasdef $argv[1]
        # split aliasdef on first '=':
        set aliasname (string split -m 1 = $aliasdef)[1]
        set alias_value (string split -m 1 = $aliasdef)[2]
    end

    # echo "name: $aliasname"
    # echo "value: $alias_value"
    set --local position command
    if test $_flag_g
        set position anywhere
    end

    abbr --position $position --add $aliasname $alias_value
end
