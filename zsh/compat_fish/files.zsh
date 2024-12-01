## general cd
abbr cdr 'cd "$(_repo_root)"' # * favorite

## open
abbr orr 'open "$(_repo_root)"' # can't use `or` in fish :)
abbr oh 'open .'

####### vscode aliases:
abbr ch 'code .' # * favorite
abbr cih 'code-insiders .'
abbr cr 'code "$(_repo_root)"' # * favorite
abbr cir 'code-insiders "$(_repo_root)"'
## adv
abbr cie 'code --inspect-extensions=9229 .' # attach then with devtools, mostly adding this so I remember it
abbr cieb 'code --inspect-brk-extensions=9229 .' # attach, set breakpoints, then run!

#### zed
abbr zh 'zed .'
abbr zr 'zed "$(_repo_root)"'
abbr zph 'zed-preview .'
abbr zpr 'zed-preview "$(_repo_root)"'

### cursor
abbr cs 'cursor .'
abbr csr 'cursor "$(_repo_root)"'

# z
abbr zx 'z -x'

# tar:
abbr tarx 'tar -xf' # e(x)tract
abbr tart 'tar -tf' # lis(t) / (t)est
abbr tarc 'tar --xz -cf' # create xz (todo use set-position to put cursor in name that already has .txz extension)
abbr tarcg 'tar --gzip -cf' # create gzip (todo use set-position to put cursor in name that already has .tgz extension)
abbr tarcb 'tar --bzip2 -cf' # create bzip2 (todo use set-position to put cursor in name that already has .tbz2 extension)
