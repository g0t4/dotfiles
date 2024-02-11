
#
# *** Previously I concluded that pre-emptive ealiases were a waste of time. Mostly b/c I would only encounter them if I were editing my aliases. However, during fish's tab completion it is now possible to search on description too, therefore it may make sense to pre-emptively add ealiases for commands that I anticipate using / want to learn... also lesser used aliases that I want to habituate can be found with desc search too (just today I forgot what I setup for `git config` so I hit gc<TAB>, Ctrl+S => 'config' and found gconf that I recently modified!)
# - previously I could search aliases (name/value) so this isn't technically new, just convenient to be integrated into tab completion versus a standalone command (i.e. agr ealias to grep aliases in zsh)
#
# ealias is a big part of what I use in my dotfiles in terms of zsh customization.... a adapater alone for this would make fish much more usable to test drive it...

# expensive to setup options spec (1/3 of each call to ealias) so do it once (does result in global scope) => saves 100+ ms overall
set ealias_options (fish_opt --short=g) (fish_opt --short=n --long=NoSpaceAfter --long-only) # explicit arg specs! ==> same as 'g' but this is clear
# FYI fish --profile-startup=startup.log:
#   durations are in MICROSECONDS
#   Time column = total time MINUS nested time (current only)
#   Sum column total time (current+nested)
#   src here: https://github.com/fish-shell/fish-shell/blob/master/src/parser.rs#L185-L211
#   there is no count across invocations of a given statement (ie ealias is called 600+ times, search for dupes to understand where optimization may help) => i.e. given # of calls to ealias it is well worth the time to optimize it

function ealias --description "map ealias to fish abbr(eviation)"

    # wow I already like fish scripting way better than zsh/bash!

    # FYI NoSpaceAfter was a hack that worked well enough but might need polish / bug fixes
    argparse $ealias_options -- $argv # removes matching specs from $argv

    # WIP optimizing => calc count one time shaves ~130ms overall!?
    set -l num_args (count $argv)

    if test $num_args -eq 0 || test $num_args -gt 2
        echo "invalid alias definition:"
        echo "  ealias <aliasname>=<alias_value>"
        echo "  ealias <aliasname> <alias_value>"
        return
    end

    # PRN use argparse on positionals?
    if test $num_args -eq 2
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

    # register to expand (when typed)
    if test $_flag_NoSpaceAfter
        abbr --position $position --add $aliasname --set-cursor="!" "$alias_value!"
    else
        abbr --position $position --add $aliasname $alias_value
    end
    #
    # register to execute (i.e. when used in a function, such as `gsl`=>`glo; gst`)

    # problematic abbreviations to alias:
    # seems like alias is a helper to build a function? and its failing when value is complex (ie has | or '" quotes)
    #  => `type alias` => here we go! it is a function!
    # TODO build function directly? this appears to be quoting issue
    if string match -q -r '^\s*\|' $alias_value
        # my global aliases that are `| foo` are problems for whatever fish does to make func out of alias
        return
    end

    # FYI alias failure causes:
    # - alias value has odd number of " (something to do with how alias is a wrapper to create a function)
    # - alias name is reserved word
    if test $_flag_g
        # skip global aliases (don't make sense in command position anyways, derp wes)
        #  and I don't see a need to use them in a function in another position (would be confusing to read)
        # - global aliases like byml=`| bat -l yml` (doesn't make sense in command position anyways)
        return
    end

    # alias $aliasname $alias_value
    #   !!! alias is very expensive => appears to be 200us => 120+ms overall
    #   can I define a func instead? => I imagine b/c alias is a wrapper for a func then it has to generate fish code and eval it? => 
    #   YUP, sources => https://github.com/fish-shell/fish-shell/blob/master/share/functions/alias.fish#L70-L72
    #
    # define func directly, to inline what I need from alias to cut some of the delay
    # - FYI I may have issues with infinite recursion if name=$aliasname is start of $alias_value (body)
    # - FYI to validate these funcs work, comment out `abbr` calls above so you can call the function
    # PRN do I really need to define the alias? TODO review why I added this and see if I can remove/modify some other way?
    echo "function $aliasname; $alias_value \$argv; end" | source # The function definition in split in two lines to ensure that a '#' can be put in the body.
    # - saved 100ms+ vs using alias def above
end
