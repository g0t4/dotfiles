# Note: alias collisions to avoid:
# `go*` for `go` commands
# `grep` for default grep params
# `gi*` for my git ignore customizations
# `globurl`

ealias g='git'

# status
ealias gst='git status'
ealias gsl='gst && echo && glo' # * try
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
# - w/ message
ealias gcmsg='git commit -m "' -NoSpaceAfter
ealias gcam='git commit -a -m "' -NoSpaceAfter
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

# log
## https://git-scm.com/docs/git-log
#    ! https://git-scm.com/docs/gitrevisions (for how to express revision ranges)
#       @ = HEAD
#       {push} = where push to (for branch specified)
#         HEAD@{push}~1..HEAD       # long form / explicit
#         @{push}~1..               # short form (force myself to learn syntax)
#           # cannot use "origin" unless origin/HEAD specified
#       {upstream} = IIUC where pull from
#       term: triangular workflow (pull from remote A and push to remote B)
#       if, not in a triangular workflow (push/pull to same remote) then {push} = {upstream} = {u}
#         HEAD@{upstream}~1..HEAD   # long form
#         @{u}~1..                  # shortest form
#
# *** USE git config pretty.format to set default style!!!
ealias glf='git log'
for i in {1..10}; do ealias gl$i="git log -$i"; done # last N commits # !FISHISSUE => use abbr + regex + func to expand this to any number and not need a loop! # split zsh specific loop out and keep in zsh files only
# ! fish like: (super fast hack to test it)
# # gl11 => git log -11 # YEAH!
# abbr --regex 'gl\d+' --function glX  gl
# function glX
#   string replace --regex '^gl' 'git log -' $argv
# end
# ! end fish like
#
local _unpushed_commits="HEAD@{push}~1..HEAD"
ealias glo="git log ${_unpushed_commits}"
ealias glp="git log --patch ${_unpushed_commits}" # include patch (diff)
for i in {1..10}; do ealias glp$i="git log --patch -$i"; done # last N commits # !FISHISSUE abbr+regex!
ealias gls="git log --stat ${_unpushed_commits}" # summary of file changes
for i in {1..10}; do ealias gls$i="git log --stat -$i"; done # last N commits # !FISHISSUE abbr+regex!
ealias glg="git log --graph ${_unpushed_commits}" # graph of changes

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
# tracked branch
function git_current_branch() {
  # zsh has smth for this?
  git rev-parse --abbrev-ref HEAD
}
ealias ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'
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
ealias gsmf='git submodule add --branch master'
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
ealias gd="git diff --word-diff=color"
# PRN add gdnw not word-diff? for now I can just remove the arg from gd's expansion ... I prefer word-diff=color (color only) most of the time
ealias gdc="git diff --cached --word-diff=color"
ealias kgdc="git diff --cached" # common typo alias (cmd+k clear => kgst)
# last commit diff:
ealias gdlc="git log --patch HEAD~1..HEAD"
ealias gdlc1="gdlc"
for i in {2..10}; do ealias "gdlc$i"="git log --patch HEAD~$i..HEAD~$(($i - 1))"; done # !FISHISSUE abbr+regex!
ealias gdlf='git diff-tree -r HEAD~1 HEAD'
#
ealias dsf='diff-so-fancy'

# VCS in general:
ealias rr='_repo_root'
# prd = print repo directoy ;) (like pwd)
alias prd='echo $(rr)' # don't expand this alias! it just returns a path
function _repo_root() {
  if git rev-parse --is-inside-work-tree 2>/dev/null  1>/dev/null; then
    git rev-parse --show-toplevel 2>/dev/null
  elif hg root 2>/dev/null  1>/dev/null; then
    hg root 2>/dev/null
  else
    pwd
  fi
}
