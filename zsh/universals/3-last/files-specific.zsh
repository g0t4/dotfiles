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

### DISK USAGE ###
ealias du='du -h'  # tree command doesn't show size of dirs (unless showing entire hierarchy so not -L 2 for example, so stick with du command)
ealias dua='du -ha' # show all files
for i in {1..10}; do ealias du$i="du -hd $i"; done # show only N levels deep
for i in {1..10}; do ealias dua$i="du -had $i"; done # show all files only N levels deep
#
ealias df='df -h'
# Mac HD: (if fails try df -h and update this alias to be be more general)
ealias dfm='df -h /System/Volumes/Data'

## loop helpers
ealias forr='for i in {1..3}; do echo $i; done'
