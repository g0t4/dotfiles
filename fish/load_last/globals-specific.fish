
# use p(ext) unless prominent, in which use shortened p(e) format (ensure not gonna need to not expand that often)
abbr --position anywhere -- pbat '| bat -l'
abbr --position anywhere -- pgr '| grep -i'
abbr --position anywhere -- phelp '| bat -l help'
abbr --position anywhere -- pini '| bat -pl ini'
abbr --position anywhere -- pjq '| jq .' # shortened
abbr --position anywhere -- pmd '| bat -pl md' # shortened
abbr --position anywhere -- prb '| bat -pl rb'
abbr --position anywhere -- psh '| bat -pl sh'
abbr --position anywhere -- pxml '| bat -l xml' # shortened
abbr --position anywhere -- pyml '| bat -l yml' # shortened

abbr --position anywhere -- hC '| hexdump -C'
abbr --position anywhere -- pcp '| pbcopy' # copy to clipboard
# i.e.    echo -n $IFS | hexdump -C

abbr --position anywhere -- pxargs '| xargs -I {} -- echo {}'
# PRN helper for multiple commands or complex commands pased to xargs
#   dpkg -L cups-browsed | xargs -I {} sh -c 'test -d "{}" && echo "{}"'
#     lightning fast in bash relative to fish -c overhead
#     *** just use bash or /bin/sh -c # plenty fast and likely suits my needs most of the time

