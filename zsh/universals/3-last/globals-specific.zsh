#
# ! TODO port to powershell (might need to impl global aliases as currently I believe my pwsh expander is when in command position only)

ealias pgr='| grep -i' -g
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

ealias hC='| hexdump -C' -g
# i.e.    echo -n $IFS | hexdump -C
