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

#
# TODO - do I want cdn? it is fine for now ealias cdn="cd_to_dir_of"
cd_to_dir_of() {
  local _type=$(whence -w "$@")
  echo "${_type}"
  # NOTE: this isn't strictly necessary but I like to see the type :)

  # considerations: behave like cdc (resolve symlinks, parent of file that its defined in, etc)
  #   PRN find a way to locate where an alias is defined and do the same thing for aliases (cd to dir of file that defines alias)
  #   must have (to be diff than cdc): work for shell functions
  # get type:

  # cases:
  # - whence -v _pip # also _ansible
  #     _pip is an autoload shell function
  # - whence -v python3
  #     python3 is /opt/homebrew/bin/python3
  # - whence -v pyenv_prompt_info
  #     pyenv_prompt_info is a shell function from /Users/wes/repos/wes-config/oh-my-zsh/lib/prompt_info_functions.zsh
  # - no path: (for now, TODO is there a way to get path to where any name is defined?)
  #   whence -v agr
  #     agr: aliased to alias | grep -i
  # - not loaded (shell function):
  #   whence -v _ansible # or _pip
  #     _ansible is an autoload shell function
  _whencev=$(whence -v "$@" | grep -o '\s*/.*$')
  if [[ $? -ne 0 ]]; then
    echo "name not found..."
    # todo ealias lookup
    return
  fi

  # note I could match a regex group with grep to avoid space but meh
  cd_to_dir_of_file $(echo $_whencev | tr -d ' ')
}

# cd to the dir that houses a command (follow symlinks)
cd_to_dir_of_command() {
  # FYI: this is not 100% same as cdn b/c an alias can take precedence over a command and thus wins out with whence -v (in cdn) but =foo implies first matching command (not aliases,etc) so this would help me cd to command even if it's not first in path to handle a given name... not sure if that's good or bad?
  cd_to_dir_of_file =${1}
  #! FISH impl =CMD abbreviation expansion
}

ealias cdc="cd_to_dir_of_command"

# if I pass file to cd it should just go to folder of file
# dereferences symlinks (super useful for the spaghetti from brew installs)
# test with: `cdd =python3.11`
cd_to_dir_of_file() {
  # TODO PRN: feels like I should be able to combine this into cdn paradigm (along with cdc)
  #   TODO: if so, use `cdd` for the command as I like that
  local _cd_path="$@"

  if [[ ! -e $_cd_path ]]; then
    echo "${_cd_path} not found"
    return
  fi

  # if path is a symlink then fully resolve the target (recursively)
  # echo "0: ${_cd_path}"
  if [[ -L $_cd_path  ]]; then
    echo "symlink:\n   ${_cd_path} =>"
    _cd_path=$(readlink -f $_cd_path)
    # leaving this here as its nice to see when it happens!
    # echo " ${_cd_path}"
  fi

  if [[ -d $_cd_path ]]; then
    # if a directory, change right to it (not its parent)
    cd "${_cd_path}"
  else
    # if a file, then cd to its parent
    cd "${_cd_path:h}"
  fi

  log_md "cd $(pwd)"
}
ealias cdd="cd_to_dir_of_file "
