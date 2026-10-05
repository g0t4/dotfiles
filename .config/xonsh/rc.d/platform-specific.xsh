import os
import re

from wes_abbreviations import abbr, reminder_abbr
from wes_fish_migration import abbr_from_fish_function

# FYI! MANUALLY SYNC CHANGES... FAR EASIER! OR JUST DON'T BOTHER WITH FISH

$man_cmd = "man"
if $IS_MACOS:
    # gman has --regex among other improvements
    $man_cmd = "gman"

abbr('man', 'gman')
reminder_abbr('man_commands_1', f'{$man_cmd} 1')
reminder_abbr('man_syscalls_2', f'{$man_cmd} 2')
reminder_abbr('man_c_stdlib_3', f'{$man_cmd} 3')
reminder_abbr('man_kernel_interfaces_4', f'{$man_cmd} 4')
reminder_abbr('man_file_formats_5', f'{$man_cmd} 5')
reminder_abbr('man_misc_7', f'{$man_cmd} 7')
reminder_abbr('man_system_8', f'{$man_cmd} 8')
reminder_abbr('man_kernel_dev_9', f'{$man_cmd} 9')
abbr(re.compile('manlist[0-9]'), abbr_from_fish_function('manlistX'))
abbr('man1', f'{$man_cmd} 1')
abbr('man2', f'{$man_cmd} 2')
abbr('man3', f'{$man_cmd} 3')
abbr('man4', f'{$man_cmd} 4')
abbr('man5', f'{$man_cmd} 5')
abbr('man6', f'{$man_cmd} 6')
abbr('man7', f'{$man_cmd} 7')
abbr('man8', f'{$man_cmd} 8')
abbr('man9', f'{$man_cmd} 9')

abbr('mana', f'{$man_cmd} --all --regex')  # -a = all, -w = list path(s) open all matching pages
abbr('mank', 'apropos')  # man -k ~= apropos
abbr('manf', 'whatis')  # man -f == whatis

# * gnu man short => long options
# # FYI for now, if I type -k/-K standalone then I will expand it (but I won't expand it in my abbrs below where -K matches my intuition)
$man_commands = ($man_cmd,) # TODO why can't I set to multiple commands?
abbr('-K', '--global-apropos', commands=$man_commands)
abbr('-k', '--apropos', commands=$man_commands)
abbr('-w', '--where', commands=$man_commands)
abbr('-a', '--all', commands=$man_commands)

# I have -K/-w mostly burned into memory... so keep these:
abbr('manK', f'{$man_cmd} -K')  # I recall K all the time so I like manK in this case
abbr('manw', f'{$man_cmd} --where -K')  # man -w == whereis for man pages, or map to whereis?

# long term I wanna use a `gr` style:
abbr('mgr', f'{$man_cmd} -K')  # [m]an [gr]ep (common pattern I use is *gr for grep)
abbr('mgrw', f'{$man_cmd} --where -K')  # --where/--path/--location (print the location)
# i.e. gman -w -K autostash
# note -K is slow, hence why by default it starts showing pages it finds so you can look at them while it searches (presumably it continues searching in bg?)

abbr('manbash', f'{$man_cmd} $HOME/repos/github/g0t4/bash/doc/bash.1')
# use newest build of bash man page (at least don't use 3.2 from apple!)
abbr('mbash', f'{$man_cmd} $HOME/repos/github/g0t4/bash/doc/bash.1')

if $IS_MACOS:
    # force pages in homebrew installed manpages to WIN
    #  that way the manpage there for bash always takes precedence
    #  and I NEVER see bash 3.2 from Apple's crap
    #    that you cannot DELETE EITHER in /usr/share/man/man1/bash.1
    # * : to prepend (test with manpath command)
    $MANPATH = "/opt/homebrew/share/man:"

# * SED

$sed_cmd = "sed"
if $IS_MACOS:
    $sed_cmd = "gsed"

abbr('sed', 'gsed')
abbr('sede', f"{$sed_cmd} -Ei 's/%//g'", cursor_marker="%")
abbr('sedd', f"{$sed_cmd} --debug -i 's/%//g'", cursor_marker="%")
abbr('sedi', f"{$sed_cmd} -i 's/%//g'", cursor_marker="%")
abbr('rg', '(rg --files-with-matches %)', position="anywhere", commands=($sed_cmd,), cursor_marker="%")
abbr('*nd', "--glob '!datasets'", position="anywhere", commands=('rg',))
abbr('seda', f"{$sed_cmd} -Ei 's/%//g' $(@lines rg --files-with-matches ___) ", cursor_marker="%")
abbr('*a', '$(@lines rg --files-with-matches ___) ', position="anywhere", commands=($sed_cmd,))
abbr(re.compile('(lines|catr|catrange|sedr|sedrange)\\d+[,_-]\\d+'), abbr_from_fish_function('_cat_range_abbr'))
