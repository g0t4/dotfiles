#!/usr/bin/env fish

# \\\' is to filter out a few records with \' escaped in ' which fish supports but bash does not
#  PRN rewrite in fish to port easier to bash?

#  BTW... some things may "run" but not work the same if there's a runtime discrepancy

# skip options I am not ready to parse yet
#  ' -- ' after arg ensures not a match in the abbr's "key value" positional args
# | grep -vE '\-\-(regex).* -- '
abbr | sort | grep -v "\\\'" | grep -v "\-- -F" >.generated.aliases.bash

# ** MAKE SURE TO TEST THIS IN SAME SHELL (fish, see shebang above)...
#   b/c bash treats \ as literal inside  '' but fish doesn't
#   hence 4 \ => 8 \ in fish
#
# *fish versions:
# gsed -n 's/\\\\\\\\d/[0-9]/gp'    .generated.aliases.bash # preview w/ drop -i, add -n... add p => /gp
gsed -i 's/\\\\\\\\d/[0-9]/g' .generated.aliases.bash
#
# bash version (\ is literal in '' => hence four \ works)
# gsed -n 's/\\\\d/[0-9]/gp'    .generated.aliases.bash
#

# sort both just to be safe, else comm won't work
comm -23 (abbr | sort | psub) (sort .generated.aliases.bash | psub) >.generated.skipped.bash
