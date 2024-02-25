
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
