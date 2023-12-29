# !!!! LOADS WITH ealias adapter to abbr in fish!

# Note: alias collisions to avoid:
# `go*` for `go` commands
# `grep` for default grep params
# `gi*` for my git ignore customizations
# `globurl`

ealias g='git'

# status
ealias gst='git status'
ealias gsl='gst && echo && glo' # * try # FYI requires gst/glo aliases(funcs) to work
ealias gstg='git status' # common typo
ealias kgst='git status' # common typo alias (cmd+k clear => kgst)
ealias gss='git status -s'
ealias gsb='git status -sb'
ealias gsu='git status --untracked-files'
ealias gsa='git status --ignored'

# reset
ealias grhh='git reset --hard HEAD' # last commit hard reset
ealias grsh='git reset --soft HEAD~1' # previous commit soft reset to review it and then purge by grhh or gco etc
# clean
ealias gclean='git clean -id'
ealias gpristine='git reset --hard && git clean -dffx'

# reflog
ealias grl='git reflog'
ealias grla='git reflog --all'

# add
ealias ga='git add'
ealias gav='git add --verbose' # verbosity in what is added
ealias gaa='git add --all'
ealias gaaa='git add --all' # common typo
ealias gau='git add --update' # don't add new files, just changed files (either already indexed or head?)
ealias gap='git add --patch' # * favorite # patch = interactive, but skips first menu and goes right to patch

# branch read:
# don't use pager on git branch (read commands)
ealias gbv='PAGER= git branch -vv' # -v for last commmit (sha+message) & -vv adds remote tracked branch
ealias gba='PAGER= git branch --all -vv'
ealias gbr='PAGER= git branch --remotes -vv'
# branch delete:
ealias gbd='git branch --delete'
ealias gbD='git branch -D'
ealias gbdf='git branch --delete --force' #same as gbD

# bisect
# ealias gbs='git bisect'
# ealias gbsb='git bisect bad'
# ealias gbsg='git bisect good'
# ealias gbsr='git bisect reset'
# ealias gbss='git bisect start'

# blame
ealias gbl='git blame -b -w' # -w ignore whitespace, -b blank SHA1 for boundary commits

# commit and forget
ealias gcrefactor="git commit -a -m 'refactor'"
ealias gcnotes="git commit -a -m 'notes'"
ealias gmark="git commit -a -m 'mark'"

# FYI pwsh has many builtin aliases stating with 'g' b/c Get :)
#   gcm = Get-Command, gc = Get-Content
# commit
ealias gc='git commit -v' # FYI gc=Get-Content in powershell (I am very tempted to overwrite it!) ... I always want a gc command and struggle to find it
ealias gcv='git commit -v' # keeping around b/c I will need this on pwsh
ealias gca='git commit -v -a'
# - amend
ealias gc!='git commit -v --amend'
ealias gcn!='git commit -v --no-edit --amend'
ealias gca!='git commit -v -a --amend'
ealias gcan!='git commit -v -a --no-edit --amend'

# checkout
ealias gco='git checkout'
ealias gcop='git restore --patch' # interactive restore (like git add --patch) - FYI prefer git restore over git checkout
ealias gcob='git checkout -b'

# I'm always flumoxed to find the scope of config options to edit with confidence
ealias gconf='grc git config --list --show-origin --show-scope' # show files where set (ie scope's file)

# clone
ealias gcl='git clone --recurse-submodules'

# shortlog
# git shortlog -sn

# cherry pick
# ealias gcp='git cherry-pick'
# ealias gcpa='git cherry-pick --abort'
# ealias gcpc='git cherry-pick --continue'

# fetch
ealias gf='git fetch'
ealias gfa='git fetch --all --prune --jobs=10' # * favorite

# push
ealias gp='git push'
# FYI gpr is a command so be careful # * what about submodules?
ealias gpd='git push --dry-run'
ealias gpf='git push --force'
# ealias gpoat='git push origin --all && git push origin --tags'
#
# pulling
ealias gl='git pull'
ealias glr='git pull --recurse-submodules' # keep separate alias for now as its time consuming to pull multiple submodules
#
#
# remotes
ealias gr='git remote'
ealias grv='git remote -v' # * favorite
ealias gra='git remote add'
ealias grset='git remote set-url'
ealias grup='git remote update'

# rebasing
ealias grb='git rebase'
ealias grbi='git rebase -i'
ealias grba='git rebase --abort'
ealias grbc='git rebase --continue'
ealias grbs='git rebase --skip'

# reverting
ealias grev='git revert'

# removing
ealias grm='git rm'
ealias grmc='git rm --cached'

# restoring
ealias grst='git restore --staged'
ealias grsp='git restore --stage --patch' # * try this
ealias grp='git restore --patch' # * favorite
ealias grss='git restore --source'

# show
ealias gsh='git show'
ealias gsps='git show --pretty=short --show-signature'

# submodules
ealias gsm='git submodule'
ealias gsma='git submodule add --branch master'
ealias gsmd='git submodule deinit'
ealias gsmf='git submodule foreach'
ealias gsmfgl='git submodule foreach --recursive git pull'
ealias gsme='git submodule foreach'
ealias gsmi='git submodule init'
ealias gsmu='git submodule update --remote --recursive'
ealias gsmst='git submodule status --recursive'

# # stashing
# ealias gsta='git stash push'
# ealias gstaa='git stash apply'
# ealias gstc='git stash clear'
# ealias gstd='git stash drop'
# ealias gstl='git stash list'
# ealias gstp='git stash pop'
# ealias gsts='git stash show --text'
# ealias gstu='git stash --include-untracked'
# ealias gstall='git stash --all'

# switching branches
ealias gsw='git switch'
ealias gswc='git switch -c'

# tagging
ealias gts='git tag -s'
ealias gtv='git tag | sort -V'

# update-index
# prn # gignore alias => find it and add back here
# ealias gunignore='git update-index --no-assume-unchanged'

# whatchanged (logs)
ealias gwch='git whatchanged -p --abbrev-commit --pretty=medium'

## diff
# * what happened to my usage of diff-so-fancy vs gdcw/gdw ... for some reason I wanted to use dsf instead but then had issues w/ it IIRC in windows/wsl so I gah... just look into this again if it becomes a hassle here
ealias gd="git diff --color-words"
ealias gdc="git diff --cached --color-words"
ealias kgdc="git diff --cached" # common typo alias (cmd+k clear => kgst)
# last commit diff:
ealias gdlf='git diff-tree -r HEAD~1 HEAD'
#
ealias dsf='diff-so-fancy'

## LFS
#
ealias lfs="git lfs"
ealias lfsi="git lfs install"
ealias lfsls="git lfs ls-files"
ealias lfsm="git lfs migrate"
ealias lfspr="git lfs prune"
ealias lfsst="git lfs status"
ealias lfst="git lfs track '*.EXT'"
ealias lfsup="git lfs update"
ealias lfsut="git lfs untrack '*.EXT'"
ealias lfsv="git lfs version"
