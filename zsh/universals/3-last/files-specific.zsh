# here is how this is defined in OMZ:
#      alias -g ...='../..'
#      alias -g ....='../../..'
#      alias -g .....='../../../..'
#      alias -g ......='../../../../..'
#      *** setopt AUTO_CD => means a dir name in command position => cd dirname   ===> THUS .. = cd ..
#         *** don't define `alias ..` b/c it interferes with AUTO_CD!
for i in {3..10}; do
  name=$(printf '.%.0s' {1..$i})
  iminus1=$((i - 1))
  value=$(printf '../%.0s' {1..$iminus1})
  alias -g $name="cd $value"
  # don't use ealias! (won't help to see the ../../../ )
done

# ! TODO move other file related ZSH SPECIFIC helpers here
# ! ie omz-lib-directories.zsh
