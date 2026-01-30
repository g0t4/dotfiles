# use p(ext) unless prominent, in which use shortened p(e) format (ensure not gonna need to not expand that often)
abbr --position=anywhere -- pbat '| bat -l'
abbr --position=anywhere -- pgr '| rg -i --no-column' # FYI --no-column disables line numbers too (in my testing) else --no-line-number/-N is needed
abbr --position=anywhere -- pgrv '| rg -i --no-column -v' # inverted match
abbr --position=anywhere -- phelp '| bat -l help'
abbr --position=anywhere -- pini '| bat -pl ini'
abbr --position=anywhere -- pjq '| jq .'
abbr --position=anywhere -- pjqr '| jq -r .'
abbr --position=anywhere -- pjqj '| jq --join-output .' # shortened (-r w/o trailing newline)
abbr --position=anywhere -- pmd '| bat -pl md'
abbr --position=anywhere -- prb '| bat -pl rb'
abbr --position=anywhere -- psh '| bat -pl sh'
abbr --position=anywhere -- pxml '| bat -l xml'
abbr --position=anywhere -- pyml '| bat -l yml'
abbr --position=anywhere -- puniq '| sort | uniq -c'
abbr --position=anywhere -- psort '| sort -h' # TODO? include -h or not by default?

# * head abbrs
# ph<SPACE> => | head
#  I would use pipe_head for this abbr but you cannot tab complete abbrs outside of command position... so have to add | myself then I can tab complete the h10 below
abbr --position=anywhere --add _head_pipe_d --regex 'ph\d+' --function _abbr_expand_head_pipe_d
# h10<SPACE> in cmd position
abbr --add _head_d --regex 'h\d+' --function _abbr_expand_head_pipe_d
function _abbr_expand_head_pipe_d
    set text (string replace --regex "^p" "| " $argv[1]) # replace p => |
    set text (string replace --regex 'h(\d+)$' 'head -\1' $text) # h10 => head -10
    echo $text
end
#
# * tail abbrs
abbr --position=anywhere --add _tail_pipe_d --regex 'pt\d+' --function _abbr_expand_tail_pipe_d
abbr --add _tail_d --regex 't\d+' --function _abbr_expand_tail_pipe_d
function _abbr_expand_tail_pipe_d
    set text (string replace --regex "^p" "| " $argv[1]) # replace p => |
    set text (string replace --regex 't(\d+)$' 'tail -\1' $text) # t10 => tail -10
    echo $text
end

abbr --position=anywhere -- pwc '| wordcount'

abbr --position=anywhere -- hC '| hexdump -C'
abbr --position=anywhere -- pcp '| pbcopy' # copy to clipboard
# i.e.    echo -n $IFS | hexdump -C

# use `pxargs` if `px` is a problem
# TODO I would like to wrap xargs with some more features... i.e. show command colorfully / bold so it is clear vs regular output
abbr --set-cursor --position=anywhere -- px '| xargs --verbose -I_ -- % _' # --verbose == show command before running it
abbr --set-cursor --position=anywhere -- pxi '| xargs --interactive -I_ -- % _' # --interactive == show cmd and approve yes/no each one
# PRN helper for multiple commands or complex commands pased to xargs
#   dpkg -L cups-browsed | xargs -I {} sh -c 'test -d "{}" && echo "{}"'
#     lightning fast in bash relative to fish -c overhead
#     *** just use bash or /bin/sh -c # plenty fast and likely suits my needs most of the time
