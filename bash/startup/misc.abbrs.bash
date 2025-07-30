# * declare -p abbrs  # sanity check
# TODO some of these collide with docker, for now just let it happen until I find myself annoyed by using docker in bash :)... I don't think I'll be doing that... this is all just for the course series (for now)
abbr declarep "declare -p % | bat -l bash" --set-cursor
abbr dp "declare -p % | bat -l bash" --set-cursor
abbr dp_REPLY "declare -p REPLY% | bat -l bash" --set-cursor
abbr declareA "declare -A"
abbr dA "declare -A %"
abbr declarea "declare -a"
abbr da "declare -a %"
abbr declarei "declare -i"
abbr declarel "declare -l"
abbr declareu "declare -u"
abbr declaref "declare -f" # function name/definition
# abbr declareF "declare -F" # function name only # basically a way to check if function is defined

# * printf
abbr --set-cursor='!' pfv 'printf -v ! "%s"'              # capture in variable
abbr pf 'printf "%s\n"'                                   # Basic safe string output
abbr pf_exec_bash_format 'printf "%q\n"'                  # Exec-safe escaping
abbr pf_decimal 'printf "%d\n"'                           # Decimal
abbr pf_octal 'printf "%o\n"'                             # Octal
abbr pf_hex 'printf "0x%x\n"'                             # Hexadecimal with 0x prefix
abbr pf_float 'printf "%f\n"'                             # Floating point
abbr pf_scientific_notation 'printf "%e\n"'               # Scientific notation
abbr --set-cursor='!' pf_repeat 'printf "%0.s=" {1..30!}' # Print 30 '=' chars
# * echo
abbr --set-cursor ee "echo -e '%'"
abbr --set-cursor echoe "echo -e '%'"
# * read
abbr --set-cursor rr 'read -r <<<\"%\"'
abbr --set-cursor readr 'read -r <<<\"%\"'
abbr read_prompt 'read -rp "Prompt: "'                               # Prompted read
abbr read_array 'read -ra arr'                                       # Read into array, splitting on $IFS
abbr read_loop_demo 'while IFS= read -r line; do echo "$line"; done' # Loop over lines (think cat, for demo purposes)
# * mapfile/readarray
abbr mapfile_lines 'mapfile -t lines <' # Common pattern for lines[], -t strip trail delim (newline)
abbr --set-cursor mapfile_n_lines 'mapfile -n % -t lines <' # read N lines
abbr --set-cursor mapfile_str 'mapfile -t <<<"$%"' # From a multiline string
abbr --set-cursor mapfile_cmd 'mapfile -t < <(%)'   # From command output

abbr pstree_bash_shell 'pstree -p $$'

# TODO mirror with sh.snippets from my nvim config...
# * would be cool to get a full blown snippet system in bash (and other shells)...
#  ea => echo "${placeholder1[@]}" # put cursor on placeholder1 slot
#     I could do this with cursor positioning like --set-cursor in fish abbrs
#     and I had an IMPL of that in zsh prior
#     jump positions too with Ctrl-J or similar (like nvim)
# shellcheck disable=SC2016 # expressions in single quotes don't expand, yup that's the point here!
abbr d@='"${%[@]}"' --position=anywhere --set-cursor
abbr d_array_length='${#%[@]}' --position=anywhere --set-cursor
abbr d_string_length='${#%}' --position=anywhere --set-cursor
abbr d*='"${%[*]}"' --position=anywhere --set-cursor
# do not always need {}
abbr dx='"$%"' --position=anywhere --set-cursor
abbr dxb='"${%}"' --position=anywhere --set-cursor
#
abbr d_default_value_if_unset='"${%:-default_value}"' --position=anywhere --set-cursor
abbr d_swap_if_set '"${%:+use_this_if_set}"' --position=anywhere --set-cursor
abbr d_assign_if_unset '"${%:=assign_this_if_unset}"' --position=anywhere --set-cursor
abbr d_error_if_unset '"${%:?error_message_if_unset}"' --position=anywhere --set-cursor
#
abbr dxu='${%}' --position=anywhere --set-cursor
abbr echo_variable='declare -p % | bat -l bash'         # arrays and scalars
abbr echo_array_element='echo _"${%[0]}"_' --set-cursor # array item, adds [0] as a convenience (could be a 2nd placeholder in a future snippets system)
abbr echo_array_length='echo ${#%[@]}' --set-cursor
#
# aliased, see which I prefer
abbr for_in_array='for item in "${%[@]}"; do echo $item; done' --set-cursor
abbr for_in_range='for i in "{1..10%}"; do echo $i; done' --set-cursor
abbr for_in_array_indicies='for i in "${!%[@]}"; do echo "${i} ${name[$i]}"; done' --set-cursor

abbr pIFS "echo -n \"\${IFS}\" | hexdump -C" # block word splitting, or it will split it's own characters :)
#
# print path one per line... two ways to do it
abbr pPATH '(IFS=:; for p in ${PATH}; do echo $p; done)'
#
# for fun... here's a diff variant:
# echo "${PATH//:/$'\n'}"
abbr pPATH "echo \"\${PATH//:/\$'\n'}\""
#  FYI remove outermost "" around expanded arg to echo... shows how IFS works and stopping it with quoting
#
# PRN add variant using printf?
# PRN add variant using read

# * trap
abbr trapl "trap -l"
abbr trapp "trap -p"
abbr trapP "trap -P"
