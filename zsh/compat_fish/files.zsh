## general cd
ealias cdr='cd "$(_repo_root)"' # * favorite

## open
ealias or='open "$(_repo_root)"'
ealias oh='open .'

####### vscode aliases:
# no path
ealias c='code "$(_repo_root)"'
ealias cg='code --goto'
# path relative:
ealias ch='code .' # * favorite
ealias chp='code ..'
# repo relative:
ealias cr='code "$(_repo_root)"' # * favorite
ealias crg='code "$(_repo_root)" --goto'
ealias crg-use='code "$(_repo_root)" --goto FILE:LINE:COL'
# open aliases (similar idea)
