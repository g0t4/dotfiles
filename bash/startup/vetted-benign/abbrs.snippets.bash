# * declare -p abbrs  # sanity check
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
