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
abbr tarx_stdout 'tar -O -xf' # e(x)tract to std(O)ut
abbr tart 'tar -tf' # lis(t) / (t)est
abbr tarc 'tar --xz -cf' # create xz (todo use set-position to put cursor in name that already has .txz extension)
abbr tarcg 'tar --gzip -cf' # create gzip (todo use set-position to put cursor in name that already has .tgz extension)
abbr tarcb 'tar --bzip2 -cf' # create bzip2 (todo use set-position to put cursor in name that already has .tbz2 extension)

# *** java (zip)
# jar:
abbr jarx 'jar -xf' # e(x)tract
abbr jart 'jar -tf' # lis(t) / (t)est
abbr jaru 'jar -uf' # u(n)pack
abbr jarc 'jar -cf' # create
# TODO more based on jar/zip/unzip (FYI bsdtar supports zip, not gnu tar)

# *** unzip
abbr unzipx_stdout 'unzip -p' # e(x)tract to std(O)ut
abbr unzipl 'unzip -l' # lis(t) / (t)est
# TODO flesh out later, FYI use zip for create equivalaents
#   PRN make all these abbrs via zip and unzip? same set and just use respective command based on action? (unlike tar which has one command for all ops)
