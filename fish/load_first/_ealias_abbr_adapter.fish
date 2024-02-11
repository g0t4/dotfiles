
#
# *** Previously I concluded that pre-emptive ealiases were a waste of time. Mostly b/c I would only encounter them if I were editing my aliases. However, during fish's tab completion it is now possible to search on description too, therefore it may make sense to pre-emptively add ealiases for commands that I anticipate using / want to learn... also lesser used aliases that I want to habituate can be found with desc search too (just today I forgot what I setup for `git config` so I hit gc<TAB>, Ctrl+S => 'config' and found gconf that I recently modified!)
# - previously I could search aliases (name/value) so this isn't technically new, just convenient to be integrated into tab completion versus a standalone command (i.e. agr ealias to grep aliases in zsh)
#
# ealias is a big part of what I use in my dotfiles in terms of zsh customization.... a adapater alone for this would make fish much more usable to test drive it...

# expensive to setup options spec (1/3 of each call to ealias) so do it once (does result in global scope) => saves 100+ ms overall
set ealias_options (fish_opt --short=g) (fish_opt --short=n --long=NoSpaceAfter --long-only) # explicit arg specs! ==> same as 'g' but this is clear
# TODO is there a simpler way to define options like in alias function (make sure its not slower though) => see `type alias` and look at its option parsing with h/help s/save or w/e
# FYI fish --profile-startup=startup.log:
#   durations are in MICROSECONDS
#   Time column = total time MINUS nested time (current only)
#   Sum column total time (current+nested)
#   src here: https://github.com/fish-shell/fish-shell/blob/master/src/parser.rs#L185-L211
#   there is no count across invocations of a given statement (ie ealias is called 600+ times, search for dupes to understand where optimization may help) => i.e. given # of calls to ealias it is well worth the time to optimize it
# `time fish -C exit` to quick check overall timing
#   OR: `time fish --profile-startup=startup.log -C exit`
#       also grab startup log and compare us/ms to overall timing
#   w00t optimizations got me to 2.53s=>700ms! (rpi4B) + 660ms=>220ms(rpi5) + 385ms=>151ms (mbp)
#  *** careful not to use first ealias call for timing info as it loads some funcs (ie abbr first call => source /opt/homebrew/Cellar/fish/3.7.0/share/fish/functions/abbr.fish! even though abbr is builtin now),  so skip to second ealias invocation for more accurate timing into (in which case ealias right now is 150ms on mbp which is plenty fast for now => 60ms for 1k aliases and I only have 700 so that's all fine enough for now)

function ealias --description "map ealias to fish abbr(eviation)"

    # wow I already like fish scripting way better than zsh/bash!

    # FYI NoSpaceAfter was a hack that worked well enough but might need polish / bug fixes
    argparse $ealias_options -- $argv # removes matching specs from $argv
    # ! OPTIMIZE => what is strange to me is that argparse (which is a parser w/ dynamic options) only takes 7us whereas (set num_args count $argv) takes 46us and of that 19us is just count $argv?! why? they both operate on $argv and one is a hell of a lot more complex? is one written in c++ perhaps? and one in shell code? or? both set variables too?! confusing

    # not checking for invalid args saves 30+us per invocation => so, dont include what is a pre-condition as I can always add that check in manually and remove it from production code so as not to waste time on assertions in prod where it is not likely ever needed and so just bogs down real usage!

    # only support format: ealias foo=bar
    set aliasdef $argv[1]
    # split aliasdef on first '=':
    set splitted (string split -m 1 = $aliasdef) # ~30us mbp
    set aliasname $splitted[1]
    set alias_value $splitted[2]

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
    # - FYI this is needed to support compositional aliases => `gsl`=>`gst && echo && glo`
    echo "function $aliasname; $alias_value \$argv; end" | source # The function definition in split in two lines to ensure that a '#' can be put in the body.
    # - saved 100ms+ vs using alias def above
end
