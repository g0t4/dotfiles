#
# TODO modify for fishisms

# abbr
# in fish I am using abbr mostly (and right now not using alias at all though I may go back to it for ealias) so lets search through abbr instead of alias
ealias als="abbr | bat --language sh -p"
ealias agr="abbr | grep -i" # name or value contain
# temp disable agrs b/c it won't work w/o alias funcs right now as abbr output is not so easily parsed for the start of the name of an abbr
# abbr --add agrs --set-cursor='!' "alias | grep -i 'alias !'" # name starts with (fish shows `alias ` in front of each alias name so use that instead of zsh's ^ to match)

ealias els="env | bat --language dotenv -p"
ealias egr="env | grep -i "

# shell variables names and values
ealias vls="set | bat --language ini -p"
ealias vgr="set | grep -i "
