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

function take() {
  mkdir -p $@ && cd ${@:$#}
}

## cd_dir_of helpers
#
cd_dir_of_command() {
  cd_dir_of_path =${1}
}
ealias cdc="cd_dir_of_command"

cd_dir_of_path() {
  local _cd_path="$@"

  if [[ ! -e $_cd_path ]]; then
    echo "${_cd_path} not found"
    return
  fi

  # resolve symlinks (-f => recursively)
  if [[ -L $_cd_path  ]]; then
    echo "symlink:\n   ${_cd_path} =>"
    _cd_path=$(readlink -f $_cd_path)
  fi

  if [[ -d $_cd_path ]]; then
    # dir
    cd "${_cd_path}"
  else
    # file
    cd "${_cd_path:h}"
  fi

  log_md "cd $(pwd)"
}
ealias cdd="cd_dir_of_path"
