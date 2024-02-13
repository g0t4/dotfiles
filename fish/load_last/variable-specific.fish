#
# TODO modify for fishisms

# abbr
# in fish I am using abbr mostly (and right now not using alias at all though I may go back to it for ealias) so lets search through abbr instead of alias
ealias als="abbr | bat --language sh -p"
ealias agr="abbr | grep -i" # name or value contain
abbr --add agrs --set-cursor='!' "abbr | grep -i 'abbr -a -- !'" # this won't match all abbr's but will find most of them (i.e. regex won't match)

ealias els="env | bat --language dotenv -p"
ealias egr="env | grep -i "

# shell variables names and values
ealias vls="set | bat --language ini -p"
ealias vgr="set | grep -i "
