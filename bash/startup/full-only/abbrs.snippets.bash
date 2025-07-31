# * read
abbr --set-cursor rr 'read -r <<<\"%\"'
abbr --set-cursor readr 'read -r <<<\"%\"'
abbr read_prompt 'read -rp "Prompt: "'                               # Prompted read
abbr read_array 'read -ra arr'                                       # Read into array, splitting on $IFS
abbr read_loop_demo 'while IFS= read -r line; do echo "$line"; done' # Loop over lines (think cat, for demo purposes)
# * mapfile/readarray
abbr mapfile_lines 'mapfile -t lines <'                     # Common pattern for lines[], -t strip trail delim (newline)
abbr --set-cursor mapfile_n_lines 'mapfile -n % -t lines <' # read N lines
abbr --set-cursor mapfile_str 'mapfile -t <<<"$%"'          # From a multiline string
abbr --set-cursor mapfile_cmd 'mapfile -t < <(%)'           # From command output

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
abbr dxu='${%}' --position=anywhere --set-cursor
#
abbr d_default_value_if_unset='"${%:-default_value}"' --position=anywhere --set-cursor
abbr d_swap_if_set '"${%:+use_this_if_set}"' --position=anywhere --set-cursor
abbr d_assign_if_unset '"${%:=assign_this_if_unset}"' --position=anywhere --set-cursor
abbr d_error_if_unset '"${%:?error_message_if_unset}"' --position=anywhere --set-cursor
#
abbr echo_variable='declare -p % | bat -l bash'         # arrays and scalars
abbr echo_array_element='echo _"${%[0]}"_' --set-cursor # array item, adds [0] as a convenience (could be a 2nd placeholder in a future snippets system)
abbr echo_array_length='echo ${#%[@]}' --set-cursor
#
# aliased, see which I prefer
abbr for_in_array='for item in "${%[@]}"; do echo $item; done' --set-cursor
abbr for_in_range='for i in "{1..10%}"; do echo $i; done' --set-cursor
abbr for_in_array_indicies='for i in "${!%[@]}"; do echo "${i} ${name[$i]}"; done' --set-cursor


# * trap
abbr trapl "trap -l"
abbr trapp "trap -p"
abbr trapP "trap -P"
