## general cd
ealias cdr='cd "$(_repo_root)"' # * favorite

## open
ealias orr='open "$(_repo_root)"' # can't use `or` in fish :)
ealias oh='open .'

####### vscode aliases:
ealias ch='code .' # * favorite
ealias cr='code "$(_repo_root)"' # * favorite

#### zed
ealias zh='zed .'
ealias zr='zed "$(_repo_root)"'

# z
ealias zx='z -x'

# tar:
ealias tarx='tar -xf' # e(x)tract
ealias tart='tar -tf' # lis(t) / (t)est
ealias tarc='tar --xz -cf' # create xz (todo use set-position to put cursor in name that already has .txz extension)
ealias tarcg='tar --gzip -cf' # create gzip (todo use set-position to put cursor in name that already has .tgz extension)
ealias tarcb='tar --bzip2 -cf' # create bzip2 (todo use set-position to put cursor in name that already has .tbz2 extension)
