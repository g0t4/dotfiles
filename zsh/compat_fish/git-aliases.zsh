# !!!! LOADS WITH ealias adapter to abbr in fish!

# Note: alias collisions to avoid:
# `go*` for `go` commands
# `grep` for default grep params
# `gi*` for my git ignore customizations
# `globurl`

# status
ealias gst='git status'
ealias gsl='gst && echo && glo' # * try # FYI requires gst/glo aliases(funcs) to work
eabbr gss 'git status -s'
eabbr gsb 'git status -sb'
eabbr gsu 'git status --untracked-files'
eabbr gsi 'git status --ignored'

# reset
eabbr grhh 'git reset --hard HEAD' # last commit hard reset
eabbr grsh 'git reset --soft HEAD~1' # previous commit soft reset to review it and then purge by grhh or gco etc
# clean
eabbr gclean 'git clean -id'
eabbr gpristine 'git reset --hard && git clean -dffx'

# reflog
eabbr grl 'git reflog'
eabbr grla 'git reflog --all'

# add
eabbr ga 'git add'
eabbr gav 'git add --verbose' # verbosity in what is added
eabbr gaa 'git add --all'
eabbr gaaa 'git add --all' # common typo
eabbr gau 'git add --update' # don't add new files, just changed files (either already indexed or head?)
eabbr gap 'git add --patch' # * favorite # patch = interactive, but skips first menu and goes right to patch

# branch read:
# don't use pager on git branch (read commands)
eabbr gbv='PAGER  git branch -vv' # -v for last commmit (sha+message) & -vv adds remote tracked branch
eabbr gba='PAGER  git branch --all -vv'
eabbr gbr='PAGER  git branch --remotes -vv'
# branch delete:
eabbr gbd 'git branch --delete'
eabbr gbD 'git branch -D'
eabbr gbdf 'git branch --delete --force' #same as gbD

# bisect
# eabbr gbs 'git bisect'
# eabbr gbsb 'git bisect bad'
# eabbr gbsg 'git bisect good'
# eabbr gbsr 'git bisect reset'
# eabbr gbss 'git bisect start'

# blame
eabbr gbl 'git blame -b -w' # -w ignore whitespace, -b blank SHA1 for boundary commits

# commit and forget
eabbr gcrefactor "git commit -a -m 'refactor'"
eabbr gcnotes "git commit -a -m 'notes'"
eabbr gcsubs "git commit -a -m 'subs'"
eabbr gmark "git commit -a -m 'mark'"

# FYI pwsh has many builtin aliases stating with 'g' b/c Get :)
#   gcm = Get-Command, gc = Get-Content
# commit
eabbr gc 'git commit -v' # FYI gc=Get-Content in powershell (I am very tempted to overwrite it!) ... I always want a gc command and struggle to find it
eabbr gcv 'git commit -v' # keeping around b/c I will need this on pwsh
eabbr gca 'git commit -v -a'
# - amend
eabbr gc! 'git commit -v --amend'
eabbr gcn! 'git commit -v --no-edit --amend'
eabbr gca! 'git commit -v -a --amend'
eabbr gcan! 'git commit -v -a --no-edit --amend'

# checkout
eabbr gco 'git checkout'
eabbr gcop 'git restore --patch' # interactive restore (like git add --patch) - FYI prefer git restore over git checkout
eabbr gcob 'git checkout -b'

# I'm always flumoxed to find the scope of config options to edit with confidence
eabbr gconf 'grc git config --list --show-origin --show-scope' # show files where set (ie scope's file)

# clone
eabbr gcl 'git clone --recurse-submodules'

# shortlog
# git shortlog -sn

# cherry pick
# eabbr gcp 'git cherry-pick'
# eabbr gcpa 'git cherry-pick --abort'
# eabbr gcpc 'git cherry-pick --continue'

# fetch
eabbr gf 'git fetch'
eabbr gfa 'git fetch --all --prune --jobs=10' # * favorite

# push
eabbr gp 'git push'
# FYI gpr is a command so be careful # * what about submodules?
eabbr gpd 'git push --dry-run'
eabbr gpf 'git push --force'
# eabbr gpoat 'git push origin --all && git push origin --tags'
#
# pulling
eabbr gl 'git pull'
eabbr glr 'git pull --recurse-submodules' # keep separate alias for now as its time consuming to pull multiple submodules
#
#
# remotes
eabbr gr 'git remote'
eabbr grv 'git remote -v' # * favorite
eabbr gra 'git remote add'
eabbr grset 'git remote set-url'
eabbr grup 'git remote update'

# rebasing
eabbr grb 'git rebase'
eabbr grbi 'git rebase -i'
eabbr grba 'git rebase --abort'
eabbr grbc 'git rebase --continue'
eabbr grbs 'git rebase --skip'

# reverting
eabbr grev 'git revert'

# removing
eabbr grm 'git rm'
eabbr grmc 'git rm --cached'

# restoring
eabbr grst 'git restore --staged'
eabbr grsp 'git restore --stage --patch' # * try this
eabbr grp 'git restore --patch' # * favorite
eabbr grss 'git restore --source'

# show
eabbr gsh 'git show'
eabbr gsps 'git show --pretty=short --show-signature'

# submodules
eabbr gsm 'git submodule'
eabbr gsma 'git submodule add --branch master'
eabbr gsmd 'git submodule deinit'
eabbr gsmf 'git submodule foreach'
eabbr gsmfgl 'git submodule foreach --recursive git pull'
eabbr gsme 'git submodule foreach'
eabbr gsmi 'git submodule init'
eabbr gsmu 'git submodule update --remote --recursive'
eabbr gsmst 'git submodule status --recursive'

# # stashing
# eabbr gsta 'git stash push'
# eabbr gstaa 'git stash apply'
# eabbr gstc 'git stash clear'
# eabbr gstd 'git stash drop'
# eabbr gstl 'git stash list'
# eabbr gstp 'git stash pop'
# eabbr gsts 'git stash show --text'
# eabbr gstu 'git stash --include-untracked'
# eabbr gstall 'git stash --all'

# switching branches
eabbr gsw 'git switch'
eabbr gswc 'git switch -c'

# tagging
eabbr gts 'git tag -s'
eabbr gtv 'git tag | sort -V'

# update-index
# prn # gignore alias => find it and add back here
# eabbr gunignore 'git update-index --no-assume-unchanged'

# whatchanged (logs)
eabbr gwch 'git whatchanged -p --abbrev-commit --pretty=medium'

## diff
# * what happened to my usage of diff-so-fancy vs gdcw/gdw ... for some reason I wanted to use dsf instead but then had issues w/ it IIRC in windows/wsl so I gah... just look into this again if it becomes a hassle here
eabbr gd "git diff --color-words"
eabbr gdc "git diff --cached --color-words"
eabbr kgdc "git diff --cached" # common typo alias (cmd+k clear => kgst)
# last commit diff:
eabbr gdlf 'git diff-tree -r HEAD~1 HEAD'
#
eabbr dsf 'diff-so-fancy'

## LFS
#
eabbr lfs "git lfs"
eabbr lfsi "git lfs install"
eabbr lfsls "git lfs ls-files"
eabbr lfsm "git lfs migrate"
eabbr lfspr "git lfs prune"
eabbr lfsst "git lfs status"
eabbr lfst "git lfs track '*.EXT'"
eabbr lfsup "git lfs update"
eabbr lfsut "git lfs untrack '*.EXT'"
eabbr lfsv "git lfs version"
