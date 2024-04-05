
function wcl() {

  $_python = "${WESCONFIG_DOTFILES}\.venv\Scripts\python.exe"
  $_wcl_py = "${WESCONFIG_DOTFILES}\zsh\compat_fish\pythons\wcl.py"
  & $_python $_wcl_py $args

}

# TODO wrap z command like I did with fish shell
#   see notes in wcl.py about how to approach this to obviate the need to add the path to z history in wcl.py too
#   see misc-specific.fish
# function z
#     # TLDR = wcl + z
#     # FYI still uses z fish completions (b/c same name)

#     # -- ensures $argv can have options to z (i.e. --clean)
#     if string match --quiet --regex "github.com" -- $argv
#         # if a repo url then clone and/or cd to it
#         set path (wcl --path-only $argv)
#         if test -d $path
#             # PRN wcl anyways to get latest? wouldn't that be what I want when I pass a full URL http://...?
#             cd $path
#         else
#             wcl $argv
#             cd $path
#         end
#     else
#         # PRN in future detect if org/repo format ($argv)... AND if z has no matching results... then attempt to clone and cd to it...?
#         # otherwise just call z like normal
#         __z $argv
#     end
# end