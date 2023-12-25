# `open` means smartgit process is not a subprocess of shell (doesn't block shell)
alias smartgit="open -na SmartGit --args" # all args after --args are passed to smartgit
# -n => new instance each time (otherwise open is ignored if existing instance is open)
# absolute paths work, not relative

ealias sgo='smartgit --open "$(pwd)"' # open current dir's repo
# ealias sgr='smartgit --open "$(rr)"' # open repo of current folder # ! do I even need this? smartgit opens repo of PWD so why use rr to find that?
ealias sgl='smartgit --log "$(pwd)"' # open log for current dir repo
# --blame, --investigate and --status aren't working so I nuked those aliases for now (I wasn't using them anyway)

# --anchor-commit <commit>                optional commit to open the log for
# --cwd <File>                            relative paths are given relative to this absolute path
# --list-index [repository-root]          list the files of the Git index of the given directory
# --write-default-theme-file              write the default theme file
