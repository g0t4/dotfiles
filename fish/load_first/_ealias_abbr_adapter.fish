
#
# *** Previously I concluded that pre-emptive ealiases were a waste of time. Mostly b/c I would only encounter them if I were editing my aliases. However, during fish's tab completion it is now possible to search on description too, therefore it may make sense to pre-emptively add ealiases for commands that I anticipate using / want to learn... also lesser used aliases that I want to habituate can be found with desc search too (just today I forgot what I setup for `git config` so I hit gc<TAB>, Ctrl+S => 'config' and found gconf that I recently modified!)
# - previously I could search aliases (name/value) so this isn't technically new, just convenient to be integrated into tab completion versus a standalone command (i.e. agr ealias to grep aliases in zsh)
#
# ealias is a big part of what I use in my dotfiles in terms of zsh customization.... a adapater alone for this would make fish much more usable to test drive it...

# FYI known bug with new --set-cursor abbr
#    https://github.com/fish-shell/fish-shell/issues/9730
# bind --preset ' ' self-insert expand-abbr
bind ' ' self-insert expand-abbr # self-insert first since it doesn't matter before/after on " " and then --set-cursor abbr's work with ' ' trigger
# rest work with vanilla abbrs but not --set-cursor abbrs:
# bind --preset ';' self-insert expand-abbr
bind ';' expand-abbr self-insert
# bind --preset '|' self-insert expand-abbr
bind '|' expand-abbr self-insert
# bind --preset '&' self-insert expand-abbr
bind '&' expand-abbr self-insert
# bind --preset '>' self-insert expand-abbr
bind '>' expand-abbr self-insert
# bind --preset '<' self-insert expand-abbr
bind '<' expand-abbr self-insert
# bind --preset ')' self-insert expand-abbr

abbr --add agr --set-cursor='!' "abbr | grep -i '!'" # i.e. to find `git status` aliases
abbr --add agrs --set-cursor='!' "abbr | grep -i '\b!'" # i.e. for finding aliases that start with `dc` or `gs` etc => useful when creating new aliases to find a "namespace" that is free

# Next on chopping block :)
function eabbr --description "ealias w/ expand only, IOTW abbr marked compatible with ealias... later can impl eabbr in zsh too and share these definitions"
    # --wraps abbr # DO NOT setup abbr completion b/c I don't intend for eabbr to use any options from abbr (use abbr directly if not just simple ealias like expansion)
    # ** another benefit => abbr is MUST FASTER than ealias definitions (~10-100x faster)
    # ** FYI big difference is eabbrs dont have func defined so they are not composable, i.e. won't be doing 'gsl'=> 'gst && echo && glo' with eabbrs
    abbr $argv
end
