function get_fish_symbols

    # think symbols search in vscode
    # think Get-Command in powershell on steroids (gcm returns funcs, aliases, cmdlets)

    # usage:
    #   get_shell_symbols
    #       no arg, dumps all
    #   get_shell_symbols gst
    #       returns abbr, alias and funcname => think etymology of a symbol

    # PRN more advanced search would entail searching function bodies too (and other types here that have impl but don't show it with the following dump commands):
    #    for functions, can call type on each function name

    begin
        #  might need to prefix each line with the type? for cases where we just get name

        alias # even though these are functions (and thus show up in `functions`) I want to see aliasdef
        functions --all # --all => hidden too  # shows names only
        functions --handlers # missing context of event handler type, but let it be for now to see how this works or doesn't work
        builtin --names
        set # variables (all - universal, global, local, func)
        abbr # abbreviations
        # PRN what else?
        # history?
        bind --all # key bindings
        bind --function-names # avail input functions (beyond just what is bound) IIAC these are not listed in `functions` output?
    end | grep -i "$argv"

end

# OR, `fs`/`fsym` and `ffb`?
# abbr ss get_fish_symbols # conflicts with `ss` (netstat replacement)
# abbr sfb get_fish_function_bodies

function get_fish_function_bodies

    begin
        #  might need to prefix each line with the type? for cases where we just get name
        functions --all | while read -l func
            echo -e "# $func\n"
            functions $func
        end
        # prn what about bind functions?
    end # | grep -i "$argv"
    # I would like to pipe to grep but then I lose coloring which makes sense but I want to keep it for now and revisit filtering later
end
