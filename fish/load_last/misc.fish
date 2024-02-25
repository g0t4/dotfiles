
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
