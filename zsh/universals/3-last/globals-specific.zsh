#
# ! TODO port to powershell (might need to impl global aliases as currently I believe my pwsh expander is when in command position only)

# use p(ext) unless prominent, in which use shortened p(e) format (ensure not gonna need to not expand that often)
ealias pbat='| bat -l' -g
ealias pgr='| rg -i' -g
ealias phelp='| bat -l help' -g
ealias pini='| bat -pl ini' -g
ealias pjq='| jq .' -g # shortened
ealias pmd='| bat -l md' # shortened
ealias prb='| bat -pl rb' -g
ealias psh='| bat -pl sh' -g
ealias pxml='| bat -l xml' -g # shortened
ealias pyml='| bat -l yml' -g # shortened
# test with:
#    cat site.yml py => expands to 'cat site.yml | bat -l yml'
#   hmmmm if I have a command like \cat (to bypass aliases)... global aliases don't complete in this case?! ... the alias works on execution but it seems like _expand_alias is never called or it doesn't expand in this case

ealias hC='| hexdump -C' -g
# i.e.    echo -n $IFS | hexdump -C
