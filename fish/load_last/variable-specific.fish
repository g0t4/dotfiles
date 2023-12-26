#
# TODO modify for fishisms

ealias als="alias | bat --language sh -p"
ealias agr="alias | grep -i" # name or value contain

abbr --add agrs --set-cursor='!' "alias | grep -i 'alias !'" # name starts with (fish shows `alias ` in front of each alias name so use that instead of zsh's ^ to match)

ealias els="env | bat --language dotenv -p"
ealias egr="env | grep -i "

# shell variables names and values
ealias vls="set | bat --language ini -p"
ealias vgr="set | grep -i "
