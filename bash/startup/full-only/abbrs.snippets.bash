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

# * trap
abbr trapl "trap -l"
abbr trapp "trap -p"
abbr trapP "trap -P"
