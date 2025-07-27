( IFS="<"; echo "sourcing ${BASH_SOURCE[*]}")

# this is sourced for login shells only
#  bash --login/-l
#  intended for one-time setup
#  BUT, I don't want to use this for anything unless I absolutely have to
#  WHY? because by default a login shell will not include your ~/.bashrc/rcfile
#  *** AND b/c using 2+ separate startup files is a TERRIBLE way to write an if statement
#  I prefer ALL or NONE on my startup files, THUS:
source "$HOME/.bashrc"

# use is_login and is_interactive if you need to limit config to a particular env!
# FYI I moved path setup into bashrc too, don't rely on a login shell to ensure a consistent path

