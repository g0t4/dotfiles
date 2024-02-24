## general cd
eabbr cdr 'cd "$(_repo_root)"' # * favorite

## open
eabbr orr 'open "$(_repo_root)"' # can't use `or` in fish :)
eabbr oh 'open .'

####### vscode aliases:
eabbr ch 'code .' # * favorite
eabbr cr 'code "$(_repo_root)"' # * favorite

#### zed
eabbr zh 'zed .'
eabbr zr 'zed "$(_repo_root)"'

# z
eabbr zx 'z -x'

# tar:
eabbr tarx 'tar -xf' # e(x)tract
eabbr tart 'tar -tf' # lis(t) / (t)est
eabbr tarc 'tar --xz -cf' # create xz (todo use set-position to put cursor in name that already has .txz extension)
eabbr tarcg 'tar --gzip -cf' # create gzip (todo use set-position to put cursor in name that already has .tgz extension)
eabbr tarcb 'tar --bzip2 -cf' # create bzip2 (todo use set-position to put cursor in name that already has .tbz2 extension)
