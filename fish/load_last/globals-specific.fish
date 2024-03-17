
# use p(ext) unless prominent, in which use shortened p(e) format (ensure not gonna need to not expand that often)
abbr --position anywhere -- pbat '| bat -l'
abbr --position anywhere -- pgr '| grep -i'
abbr --position anywhere -- phelp '| bat -l help'
abbr --position anywhere -- pini '| bat -pl ini'
abbr --position anywhere -- pj '| jq .' # shortened
abbr --position anywhere -- pm '| bat -pl md' # shortened
abbr --position anywhere -- prb '| bat -pl rb'
abbr --position anywhere -- psh '| bat -pl sh'
abbr --position anywhere -- px '| bat -l xml' # shortened
abbr --position anywhere -- py '| bat -l yml' # shortened

abbr --position anywhere -- hC '| hexdump -C'
# i.e.    echo -n $IFS | hexdump -C
