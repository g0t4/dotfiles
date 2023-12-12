#!/usr/bin/env zsh

ealias wf="whence -f"
ealias wv="whence -v" # file it came from

ealias whwm="whence -wm" # pattern search and show `type` of the word(s) matching the word pattern
ealias whm="whence -m" # pattern search
ealias whallw="whence -wm '*'" # list all words and types
ealias whall="whence -m '*'" # list all words and types

# this page of zsh manual has good info about aliases, functions, reserved words, etc
# http://zsh.sourceforge.net/Guide/zshguide03.html
# - where I found `whence -wm`
# and was further spurred to lookup `whence` man page: `mzb` (`man zshbuiltins`):
# whence:
# - takes 1+ "name" arguments & tells you how each would be interpreted if used as a command name
# - options:
#   `-v` verbose
#   `-c` print result in `csh-like` format (includes showing shell functions)
#   `-w` instead of printing interpretation, print name's "type" (alias, builtin, command, function, hashed, reserved, or none)
#   `-f` show shell function contents
#   `-p` path search for name even if it is an alias, reserved word, shell function or builtin
#   `-m` treat names as patterns (suggested to quote them)
#   `-s` for symlinks, show the resolved (symlink-free pathname as well)
#      `-S` show all intermediate symlinks in resolving the symlink-free path
#   `-x num` in shell functions, expand tabs to [num] spaces? (IIGC)
#        "same as `functions -x` option"
#
# where ~= `whence -ca`
# which ~= `whence -c`
#
# functions ~= `typeset -f` (except args `-c` `-x` `-M` `-W`)
#
# typeset
# - read or write attributes & values for shell parameters
