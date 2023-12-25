#!/usr/bin/env zsh

# using `open` means smartgit process is not a subprocess of shell (doesn't block shell)
alias smartgit="open -a SmartGit --args" # all args after --args are passed to smartgit
#   noteworthy:
#   - if smartgit is already open the args seem ignored, it's for new instances only
#   - seems like absolute paths work and not relative paths

ealias sgo='smartgit --open "$(pwd)"' # open current dir's repo
ealias sgr='smartgit --open "$(rr)"' # open repo of current folder
ealias sgl='smartgit --log "$(pwd)"' # open log for current dir repo
ealias sgs='smartgit --status "$(pwd)"' # status of repo (.)
ealias sgb='smartgit --blame ' # add file(& optional trailing line nubmer) to open blame
ealias sgi="smartgit --investigate " # add file(& optional trailing line number) to open in DeepGit

# --anchor-commit <commit>                optional commit to open the log for
# --cwd <File>                            relative paths are given relative to this absolute path
# --list-index [repository-root]          list the files of the Git index of the given directory
# --write-default-theme-file              write the default theme file
