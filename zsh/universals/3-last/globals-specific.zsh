

#
# ! TODO ealias shim support for -g global aliases (--position=anywhere)
#
# ! TODO port to powershell (might need to impl global aliases as currently I believe my pwsh expander is when in command position only)

#   design: 'p' + file format => 'pyml' and then point it at whatever preferred colorizer/formatter tool(s) ... ie yq/bat for yml (set preferred so I don't have to think)
ealias pgr='| grep -i' -g
ealias gri='| grep -i' -g # ok so p prefix feels harder to type so maybe I don't want that? 
ealias pjq='| jq .' -g
ealias pbat='| bat -l' -g
ealias pyml='| bat -l yml' -g
ealias phelp='| bat -l help' -g
ealias pini='| bat -pl ini' -g
ealias psh='| bat -pl sh' -g
ealias prb='| bat -pl rb' -g
# test with:
#    cat site.yml byml => expands to 'cat site.yml | bat -l yml'
#   hmmmm if I have a command like \cat (to bypass aliases)... global aliases don't complete in this case?! ... the alias works on execution but it seems like _expand_alias is never called or it doesn't expand in this case

# shorcut to dump hex
ealias hC='| hexdump -C' -g
# i.e.    echo -n $IFS | hexdump -C

