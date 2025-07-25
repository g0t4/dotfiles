#!/usr/bin/env fish

# \\\' is to filter out a few records with \' escaped in ' which fish supports but bash does not
#  PRN rewrite in fish to port easier to bash?

#  BTW... some things may "run" but not work the same if there's a runtime discrepancy

# skip options I am not ready to parse yet
#  ' -- ' after arg ensures not a match in the abbr's "key value" positional args
abbr | sort | grep -vE '\-\-(regex).* -- ' | grep -v "\\\'" | grep -v "\-- -F" >.generated.aliases.bash

# sort both just to be safe, else comm won't work
comm -23 (abbr | sort | psub) (sort .generated.aliases.bash | psub) >.generated.skipped.bash
