# for quickly finding aliases by their value
ealias als="alias | bat --language sh -p"
ealias agr="alias | grep -i" # name or value contain
# TODO ISSUE - alias command pipes out '' around special chars - so searching on start would need with and without ' single quote - so I am missing aliases that have special chars when matching as is
ealias agrs="alias | grep -i ^" # name starts with

ealias els="env | bat --language dotenv -p"
ealias egr="env | grep -i "

# shell variables names and values
ealias vls="set | bat --language ini -p"
ealias vgr="set | grep -i "
ealias ols="set +o | bat --language sh -p"
ealias ogr="set +o | grep -i "
