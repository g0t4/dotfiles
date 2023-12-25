## general cd
ealias cdr='cd "$(rr)"' # * favorite

## open
ealias or='open "$(rr)"'
ealias oh='open .'

####### vscode aliases:
# no path
ealias c='code "$(rr)"'
ealias cg='code --goto'
# path relative:
ealias ch='code .' # * favorite
ealias chp='code ..'
# repo relative:
ealias cr='code "$(rr)"' # * favorite
ealias crg='code "$(rr)" --goto'
ealias crg-use='code "$(rr)" --goto FILE:LINE:COL'
# open aliases (similar idea)
