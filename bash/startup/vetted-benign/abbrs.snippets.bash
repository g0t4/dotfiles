#
# * declare
# TODO some of these collide with docker, for now just let it happen until I find myself annoyed by using docker in bash :)... I don't think I'll be doing that... this is all just for the course series (for now)
abbr declarep "declare -p % | bat -l bash" --set-cursor
abbr dp "declare -p % | bat -l bash" --set-cursor
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
abbr --set-cursor echoe "echo -e '%'"

