
# I setup wrappers in FISH to invoke these zsh functions

ealias gattr="gitattributes_for"
function gitattributes_for(){
  # todo how do I want to do this? it won't be like gi (git ignore helper) b/c these gitattributes templates seem to be not additive
  # ! most likely I want to just make my own default and stick with it always?
  curl -sfLw '\n' https://raw.githubusercontent.com/gitattributes/gitattributes/master/Web.gitattributes
  if [[ $? -ne 0 ]]; then
    return -1
  fi
}


# copied from omz example: https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/gitignore/gitignore.plugin.zsh

ealias gi="gitignores_for"
function gitignores_for() { 
  curl -sfLw '\n' https://www.gitignore.io/api/"${(j:,:)@}"
  if [[ $? -ne 0 ]]; then
    return -1
  fi
}

### begin completions
#
_gitignoreio_get_command_list() {
  curl -sfL https://www.gitignore.io/api/list | tr "," "\n"
}
#
_gitignoreio () {
  compset -P '*,'
  compadd -S '' `_gitignoreio_get_command_list`
}
#
# all of my helpers use same completions
compdef _gitignoreio gi gitignores_for append_gitignores_for commit_gitignores_for gia gic
#
### end completions

# appends to .gitignore the result of calling `gi`
# if not a git repo, then $(pwd)/.gitignore is used
# otherwise the repository root is used using `git rev-parse`
ealias gia="append_gitignores_for"
function append_gitignores_for(){
  local _topLevel=$(git rev-parse --show-toplevel)
  if [[ $? -ne 0 ]]; then
    local _gitignore="$(pwd)/.gitignore"
  else
    local _gitignore="${_topLevel}/.gitignore" 
  fi
  gitignores_for $@ >> ${_gitignore}
  if [[ $? -ne 0 ]]; then
    echo "invalid gitignore requested"
  fi
}

ealias gii="gitignore_init"
function gitignore_init(){
  commit_gitignores_for macos windows \
    images \
    visualstudiocode \
    archives \
    video
  # archives looks good for now... `compressed`` is mostly subset of archives, `compressedarchive` & `compression` are extension and need to be reviewed and likely customized/slimmed down IMO
}

# gitignore append & commit
ealias gic="commit_gitignores_for"
function commit_gitignores_for(){

  local _topLevel=$(git rev-parse --show-toplevel)
  if [[ $? -ne 0 ]]; then
    # bail if not a git repo
    echo "FAILURE: cannot commit to a non-git repo"
    echo '   use `gia` and/or create a git repo first'
    return -2
  else
    local _gitignore="${_topLevel}/.gitignore"
  fi
  echo "found top level .gitignore: ${_gitignore}"

  # ensure gitignore:
  # - not changed in working tree
  # - not changed in index
  # - not untracked, new file
  local _gitignore_status_before=$(git status --short --untracked-files ${_gitignore})
  # if anything returned about _gitignore then that implies it is dirty
  if [[ ! -z ${_gitignore_status_before} ]]; then
    echo ".gitignore is dirty, status is: ${_gitignore_status_before}"
    echo "    cannot commit unknown changes, aborting..."
    return -2
  fi

  # append to selected ignore(s)
  gitignores_for $@ >> ${_gitignore}
  if [[ $? -ne 0 ]]; then
    echo "invalid gitignore template requested"
    return -3
  fi

  # to handle untracked files gracefully, always add so they work with git commit below
  git add ${_gitignore}

  # ensure changes made, otherwise nothing to commit
  local _gitignore_status_after=$(git status --short --untracked-files ${_gitignore}) # PRN since I add before this can I drop --untracked-files flag?
  # same check as _before, inverted check... now we want to abort if no changes found (s/b modified in working directory OR new file):
  if [[ -z ${_gitignore_status_after} ]]; then
    echo "no changes to gitignore, nothing to commit, aborting..."
    return -4
  fi

  # only commit .gitignore (path passed means git commit ignores working tree and index)
  local _summary="gi $@ >> .gitignore"
  git commit -m "${_summary}" ${_gitignore}
  if [[ $? -ne 0 ]]; then
    echo "commiting changes to ${_gitignore} failed, undo with:"
    echo "    git checkout ${_gitignore}"
    return -5
  fi

}
