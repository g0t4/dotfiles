
#
# *** Previously I concluded that pre-emptive ealiases were a waste of time. Mostly b/c I would only encounter them if I were editing my aliases. However, during fish's tab completion it is now possible to search on description too, therefore it may make sense to pre-emptively add ealiases for commands that I anticipate using / want to learn... also lesser used aliases that I want to habituate can be found with desc search too (just today I forgot what I setup for `git config` so I hit gc<TAB>, Ctrl+S => 'config' and found gconf that I recently modified!)
# - previously I could search aliases (name/value) so this isn't technically new, just convenient to be integrated into tab completion versus a standalone command (i.e. agr ealias to grep aliases in zsh)
#
# ealias is a big part of what I use in my dotfiles in terms of zsh customization.... a adapater alone for this would make fish much more usable to test drive it...

# clear ealiases on reload:
set --erase ealiases
set --erase ealiases_values

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

    argparse $ealias_options -- $argv # removes matching specs from $argv

    # not checking for invalid args saves 30+us per invocation => so, dont include what is a pre-condition as I can always add that check in manually and remove it from production code so as not to waste time on assertions in prod where it is not likely ever needed and so just bogs down real usage!

    # only support format: ealias foo=bar
    set aliasdef $argv[1]
    # split aliasdef on first '=':
    # PRN refactor ealias to use two args, won't need to split on '=' => can save considerable startup time... just rework zsh impl to not use = too... probably it will be faster also!
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

    # # warn if function will lead to infinite recursion (do not leave this in prod code or it will needlessly slow down every invocation of ealias)
    # # FYI my old ealias for `ping` and `df` triggered this => I prepended `command` to avoid the recursion
    # set first_word_of_alias_value (string split " " $alias_value)[1]
    # if string match -q $aliasname $first_word_of_alias_value
    #     echo "WARNING: infinite recursion: $aliasname => $alias_value"
    # end

    # build lookup of ealiases and values (fish doesn't support a dict so I use two arrays to effectively create a dict)
    # PRN monitor for duplicate definitions (enable when testing for this) => another option would be to create a function to check for this and call at end of startup and/or on-demand
    if contains $aliasname $ealiases
        echo "WARNING: redefining ealias: $aliasname"
    end
    # - for searching ealiases (b/c abbr can't do lookups on single abbr, nor is it easy to search/grep for finding similar ealiases)
    # - for deferring function body execution until use time to optimize definition time impact of creating func below
    set --global --append ealiases $aliasname # <5us
    set --global --append ealiases_values $alias_value # careful if $alias_value ever becomes more than a single value
    # lookup (contains dcps $ealiases) => <180us is fast enough for any one off lookup
    # echo $ealiases_values[(contains -i dcps $ealiases)] # find value of an alias (if exists) => empty response otherwise

    # PRN how about pass use a defer func _ealias_func and pass $aliasname $alias_value \$argv to it and let it build the func to run at use-time not here at define-time? FYI not so simple with more complicated $alias_value like `forr` but then again I dont intend that one to be composed into other ealiases anyways so this is all fine for now
    echo "function $aliasname; $alias_value \$argv; end" | source # The function definition in split in two lines to ensure that a '#' can be put in the body.
    # - saved 100ms+ vs using alias def above
end

function ealias_lookup
    # 8to13ms on mbp21 is imperceptible when used
    set aliasname $argv[1]
    set count 0
    for i in (seq (count $ealiases))
        if string match -q $aliasname $ealiases[$i]
            set last_index $i
            set count (math $count + 1)
        end
    end
    if test $count -eq 0
        echo "No ealias found for: $aliasname"
        return 1
    else if test $count -eq 1
        echo $ealiases_values[$last_index]
        return 0
    else
        echo "Multiple ealiases found for: $aliasname"
        echo "  $count ealiases found"
        echo "  $ealiases_values[$last_index]"
        return 2
    end
end

function eabbr --description "ealias w/ expand only, IOTW abbr marked compatible with ealias... later can impl eabbr in zsh too and share these definitions"
    # --wraps abbr # DO NOT setup abbr completion b/c I don't intend for eabbr to use any options from abbr (use abbr directly if not just simple ealias like expansion)
    # ** another benefit => abbr is MUST FASTER than ealias definitions (~10-100x faster)
    # ** FYI big difference is eabbrs dont have func defined so they are not composable, i.e. won't be doing 'gsl'=> 'gst && echo && glo' with eabbrs
    abbr $argv
end
