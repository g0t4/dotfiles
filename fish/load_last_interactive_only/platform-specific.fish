
# *** man page helpers
set man_cmd man
if $IS_MACOS
    # brew install man-db
    set man_cmd gman
    abbr man gman
end
abbr man_commands_1 "$man_cmd 1"
abbr man_syscalls_2 "$man_cmd 2"
abbr man_c_stdlib_3 "$man_cmd 3"
abbr man_kernel_interfaces_4 "$man_cmd 4"
abbr man_file_formats_5 "$man_cmd 5"
abbr man_misc_7 "$man_cmd 7"
abbr man_system_8 "$man_cmd 8"
abbr man_kernel_dev_9 "$man_cmd 9"
# list all pages in a section:
abbr --regex "manlist[0-9]" --function manlistX -- manlistX
function manlistX
    set section $(string replace manlist "" $argv[1])
    echo "$man_cmd -k . | rg_grep '($section)'"
end
abbr man1 "$man_cmd 1"
abbr man2 "$man_cmd 2"
abbr man3 "$man_cmd 3"
abbr man4 "$man_cmd 4"
abbr man5 "$man_cmd 5"
abbr man6 "$man_cmd 6"
abbr man7 "$man_cmd 7"
abbr man8 "$man_cmd 8"
abbr man9 "$man_cmd 9"
#
# gman has --regex among other improvements
abbr mana "$man_cmd --all --regex" ## -a = all, -w = list path(s) open all matching pages
abbr mank apropos # man -k ~= apropos
abbr manf whatis # man -f == whatis
#
# * gnu man short => long options
#
# FYI for now, if I type -k/-K standalone then I will expand it (but I won't expand it in my abbrs below where -K matches my intuition)
abbr --command "$man_cmd" -- -K --global-apropos
abbr --command "$man_cmd" -- -k --apropos
#
abbr --command "$man_cmd" -- -w --where
abbr --command "$man_cmd" -- -a --all

# * search all manpage text (preformatted files)
#   not in macOS's man
reminder_abbr man_grep "use mgr"
reminder_abbr man_grep_list_matches "use mgrw"
#
# I have -K/-w mostly burned into memory... so keep these
abbr manK "$man_cmd -K" # I recall K all the time so I like manK in this case
abbr manw "$man_cmd --where -K" # man -w == whereis for man pages, or map to whereis?
#
# long term I wanna use a `gr` style:
abbr mgr "$man_cmd -K" # [m]an [gr]ep (common pattern I use is *gr for grep)
abbr mgrw "$man_cmd --where -K" # --where/--path/--location (print the location)
# i.e. gman -w -K autostash
# note -K is slow, hence why by default it starts showing pages it finds so you can look at them while it searches (presumably it continues searching in bg?)
#
abbr manbash "$man_cmd $HOME/repos/github/g0t4/bash/doc/bash.1"
# use newest build of bash man page (at least don't use 3.2 from apple!)
abbr mbash "$man_cmd $HOME/repos/github/g0t4/bash/doc/bash.1"
#
# force pages in homebrew installed manpages to WIN
#  that way the manpage there for bash always takes precedence
#  and I NEVER see bash 3.2 from Apple's crap
#    that you cannot DELETE EITHER in /usr/share/man/man1/bash.1
# NOTE : colon on end means this is PREPENDED to std MANPATH (so I don't lose other pages, I just put these first)
#
# must use set b/c fish has special handling for PATH vars, so cannot just use trailing : like in bash
set -x MANPATH /opt/homebrew/share/man ""
# abbr manw "whereis" ???
# PRN whereis helpers?
# PRN apropos helpers?
# PRN whatis helpers?


