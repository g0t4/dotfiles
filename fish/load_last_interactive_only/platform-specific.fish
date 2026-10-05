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

# *** sed ***

set --global sed_cmd sed
if $IS_MACOS
    set sed_cmd gsed
    abbr sed gsed # encourage gsed for uniform w/ linux distros
    #  i.e. gnu allows `sed -i` whereas BSD requires the extension `sed -i''` be passed
end
#
# * general sed abbrs:
abbr --set-cursor sede "$sed_cmd -Ei 's/%//g'"
abbr --set-cursor sedd "$sed_cmd --debug -i 's/%//g'"
abbr --set-cursor sedi "$sed_cmd -i 's/%//g'"

# * examples (can nuke if need be)
# abbr sed_duplicate_lines $sed_cmd' \'N; /^\(.*\)\n\1$/!P; D\' file'

# rg => (rg --files-with-matches __)
# use rg to limit which files are passed to sed (so not touching all files)
# use this to take your sed search regex and limit the files and then the file names are passed back
abbr --set-cursor --command $sed_cmd -- rg "(rg --files-with-matches %)"

# abbr "*l" "test redefined (do you see this in warning?)"
function build_abbrs_for_filetype
    # FYI there may be some bugs here in porting this, just heads up... use and find out

    set -l filetype_letter $argv[1]
    set -l glob_end $argv[2]
    set -l _abbr "sed$filetype_letter"

    # * two approaches to making it easier to target specific files...
    set rg_filter "(rg -g '*.$glob_end' --files-with-matches '___')"

    # 1. dedicated abbr per file type(s)
    #   i.e. sedl, sedf, sedp, etc
    abbr --set-cursor $_abbr "$sed_cmd -Ei 's/%//g' $rg_filter"

    # within rg command expand into glob filter
    # rg *l => rg -g '*.lua'
    abbr --command rg -- "*$filetype_letter" "-g '*.$glob_end'"

    # 2. *l => (rg -g "*.lua" --files-with-matches ___)
    abbr "*$filetype_letter" --command $sed_cmd $rg_filter

    # * ripgrep
    abbr "rg$filetype_letter" "rg -g '*.$glob_end'"

end

build_abbrs_for_filetype f fish
build_abbrs_for_filetype j "{json,js}"
build_abbrs_for_filetype l lua
build_abbrs_for_filetype m md
build_abbrs_for_filetype p py
build_abbrs_for_filetype t ts
build_abbrs_for_filetype r rs
build_abbrs_for_filetype y "{yaml,yml}"
build_abbrs_for_filetype x xsh

abbr --command rg -- "*nd" "--glob '!datasets'" # easily exlude datasets JSON files from shared traces

# all -  use rg w/o a filter on language (no -g *.lua for example)
abbr --set-cursor seda "$sed_cmd -Ei 's/%//g' (rg --files-with-matches ___) "
abbr --command $sed_cmd "*a" "(rg --files-with-matches ___) "

# allow , - or _ to split start/end number
#   lines1,2    lines 3-10    lines4_6
abbr _cat_range --function _cat_range_abbr --regex "(lines|catr|catrange|sedr|sedrange)\d+[,_-]\d+"
function _cat_range_abbr
    # purpose:   cat range -n '10,25p' foo.txt
    set matches (string match --regex "(\d+)_(\d+)" $argv[1])
    set start $matches[2]
    set end $matches[3]
    echo "$sed_cmd -n '$start,$end""p'"
end
