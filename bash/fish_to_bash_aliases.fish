#!/usr/bin/env fish

# \\\' is to filter out a few records with \' escaped in ' which fish supports but bash does not
#  PRN rewrite in fish to port easier to bash?

#  BTW... some things may "run" but not work the same if there's a runtime discrepancy

abbr | sort | grep -vE '\-\-(function|regex|command)' | grep -v "\\\'" >aliases.bash
