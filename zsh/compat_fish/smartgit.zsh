# `open` means smartgit process is not a subprocess of shell (doesn't block shell)
abbr smartgit "open -na SmartGit --args" # all args after --args are passed to smartgit
# -n => new instance each time (otherwise open is ignored if existing instance is open)
# absolute paths work, not relative

# FYI
#  running `/Applications/SmartGit.app/Contents/MacOS/SmartGit` directly (or cd to its dir and run it w/o abs path) works fine,
#    only have library issue if using homebrew installed smartgit cmd... odd
#    `/Applications/SmartGit.app/Contents/MacOS/SmartGit --help` will show args
#  also help: https://docs.syntevo.com/SmartGit/Latest/Command-Line-Options.html
#
# abbr sgo 'smartgit --open "$(pwd)"' # open current dir's repo
abbr sgo 'open -a SmartGit --args --open "$(pwd)"'
# FYI smartgit opens repo of PWD, no need for _repo_root
# abbr sgl 'smartgit --log "$(pwd)"' # open log for current dir repo
abbr sgl 'open -a SmartGit --args --log "$(pwd)"'
# --blame, --investigate and --status aren't working so I nuked those aliases for now (I wasn't using them anyway)

# --anchor-commit <commit>                optional commit to open the log for
# --cwd <File>                            relative paths are given relative to this absolute path
# --list-index [repository-root]          list the files of the Git index of the given directory
# --write-default-theme-file              write the default theme file


#### SMART SYNCHRONIZE

# alias ss="/Applications/SmartSynchronize.app/Contents/MacOS/SmartSynchronize" # block shell
# alias ss="open -a SmartSynchronize"
abbr smartsynchronize "open -na SmartSynchronize --args" # all args after --args are passed to SmartSynchronize
# reclaimed ss for get_shell_symbols, I don't recall ever using ss for smartsynchronize (or even launching it from CLI)

## NOTES

# /Applications/SmartSynchronize.app/Contents/MacOS/SmartSynchronize --help
# Usage: smartsynchronize [OPTION]... [--] [FILE]...
#  [FILE]...:
#   Directory Compare: <left-dir>  <right-dir>
#   File Compare     : <left-file> <right-file>
#                      <left-dir>  <right-file>
#                      <left-file> <right-dir>
#   File Merge       : <left-file> <right-file> <merge-file>

#   If just one file/dir is specified, the welcome dialog shows and suggests the
#   path in the clipboard as second path for the file or directory compare.

#   Use -- to separate options from files, even if a file is named '--help'.

# Option                                  Description
# ------                                  -----------
# -?, --help                              show this help
# --root <File>                           relative paths are given relative to
#                                           this absolute path
# --write-default-theme-file              write the default theme file