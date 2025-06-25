
# Note: alias collisions to avoid:
# `go*` for `go` commands
# `grep` for default grep params
# `gi*` for my git ignore customizations
# `globurl`

# status
abbr gsts 'git status -s'
abbr gstb 'git status -sb'
abbr gstu 'git status --untracked-files'
abbr gsti 'git status --ignored'

# reset
abbr grhh 'git reset --hard HEAD' # last commit hard reset
abbr grsh 'git reset --soft HEAD~1' # previous commit soft reset to review it and then purge by grhh or gco etc
# clean
#   (FYI leave --dry-run so I can remove it as last arg, then I don't need a second set of abbrs... b/c I should always do a quick review dryrun / or interactive)
abbr gclean 'git clean -d --dry-run' # --dry-ru[n], entire [d]irectories
abbr gcleani 'git clean -d --interactive' # [i]nteractive is alternative to dry-run
abbr gcleanx 'git clean -d -x --dry-run' # -x == ignored files too
abbr gpristine 'git reset --hard && git clean -dffx'

# reflog
abbr grl 'git reflog'
abbr grla 'git reflog --all'

# add
abbr ga 'git add'
abbr 'ga.' 'git add .'
abbr gav 'git add --verbose' # verbosity in what is added
abbr gaa 'git add --all'
abbr gaaa 'git add --all' # common typo
abbr gau 'git add --update' # don't add new files, just changed files (either already indexed or head?)
abbr gap 'git add --patch' # * favorite # patch = interactive, but skips first menu and goes right to patch
abbr gai 'git add --interactive' # patch but w/ initial menu

# branch read:
# don't use pager on git branch (read commands)
abbr gbv 'PAGER= git branch -vv' # -v for last commmit (sha+message) & -vv adds remote tracked branch
abbr gba 'PAGER= git branch --all -vv'
abbr gbr 'PAGER= git branch --remotes -vv'
# branch delete:
abbr gbd 'git branch --delete'
abbr gbD 'git branch -D'
abbr gbdf 'git branch --delete --force' #same as gbD

# bisect
# abbr gbs 'git bisect'
# abbr gbsb 'git bisect bad'
# abbr gbsg 'git bisect good'
# abbr gbsr 'git bisect reset'
# abbr gbss 'git bisect start'

# blame
abbr gbl 'git blame -b -w' # -w ignore whitespace, -b blank SHA1 for boundary commits


# gcmark like
abbr review "git commit -a -m 'review'"
abbr notes "git commit -a -m 'notes'"
# abbr gcsubs "git commit -a -m 'subs'; git push; git diff --color-words HEAD~1 HEAD"
# FYI pwsh has many builtin aliases stating with 'g' b/c Get :)
#   gcm = Get-Command, gc = Get-Content
# commit
abbr gc 'git commit -v' # FYI gc=Get-Content in powershell (I am very tempted to overwrite it!) ... I always want a gc command and struggle to find it
abbr gcv 'git commit -v' # keeping around b/c I will need this on pwsh
abbr gca 'git commit -v -a'
# - amend
abbr gc! 'git commit -v --amend'
abbr gcn! 'git commit -v --no-edit --amend'
abbr gca! 'git commit -v -a --amend'
abbr gcan! 'git commit -v -a --no-edit --amend'

# checkout
abbr gco 'git checkout'
abbr gcom 'git checkout master'
abbr gcop 'git restore --patch' # interactive restore (like git add --patch) - FYI prefer git restore over git checkout
abbr gcob 'git checkout -b'

# I'm always flumoxed to find the scope of config options to edit with confidence
abbr gconf 'grc git config --list --show-origin --show-scope' # show files where set (ie scope's file)

# clone
abbr gcl 'git clone --recurse-submodules'

# shortlog
# git shortlog -sn

# cherry pick
# abbr gcp 'git cherry-pick'
# abbr gcpa 'git cherry-pick --abort'
# abbr gcpc 'git cherry-pick --continue'

# fetch
abbr gf 'git fetch'
abbr gfa 'git fetch --all --prune --jobs=10' # * favorite

# push
abbr gp 'git push'
abbr gpsup 'git push --set-upstream origin $(git_current_branch)'
# FYI gpr is a command so be careful # * what about submodules?
abbr gpd 'git push --dry-run'
abbr gpf 'git push --force'
# abbr gpoat 'git push origin --all && git push origin --tags'
#
# pulling
abbr gl 'git pull'
abbr glr 'git pull --recurse-submodules' # keep separate alias for now as its time consuming to pull multiple submodules
#
#
# remotes
abbr gr 'git remote'
abbr grv 'git remote -v' # * favorite
abbr gra 'git remote add'
abbr grao 'git remote add origin'
abbr grau 'git remote add upstream'
abbr grsuo 'git remote set-url origin'
abbr grsuu 'git remote set-url upstream'
abbr grup 'git remote update'

# merge
abbr gm 'git merge'
abbr gma 'git merge --abort'
abbr gmc 'git merge --continue'
abbr gmff 'git merge --ff-only'

# reverting
abbr grev 'git revert'

# removing
abbr grm 'git rm'
abbr grmc 'git rm --cached'

# restore (staged)
abbr grst 'git restore --staged' # TBD do I wanna default for entire repo? or force myself to remember grstr instead?
abbr grstp 'git restore --staged --patch' # ! USE THIS MORE OFTEN (maybe make it grst?)
abbr grstr 'git restore --staged "$(_repo_root)"' # use $() syntax for compat w/ zsh too
#
# restore (unstaged)
abbr grp 'git restore --patch' # * favorite
abbr grss 'git restore --source'

# show
abbr gsh 'git show --color-words'
abbr gsps 'git show --pretty=short --show-signature --color-words'

# submodules
abbr gsm 'git submodule'
abbr gsma 'git submodule add --branch master'
abbr gsmd 'git submodule deinit'
abbr gsmf 'git submodule foreach'
abbr gsmfgl 'git submodule foreach --recursive git pull'
abbr gsme 'git submodule foreach'
abbr gsmi 'git submodule init'
abbr gsmu 'git submodule update --remote --recursive'
abbr gsmst 'git submodule status --recursive'

# # stashing
# abbr gsta 'git stash push'
# abbr gstaa 'git stash apply'
# abbr gstc 'git stash clear'
# abbr gstd 'git stash drop'
# abbr gstl 'git stash list'
# abbr gstp 'git stash pop'
# abbr gsts 'git stash show --text'
# abbr gstu 'git stash --include-untracked'
# abbr gstall 'git stash --all'

# switching branches
abbr gsw 'git switch'
abbr gswc 'git switch -c'

# tagging
abbr gts 'git tag -s'
abbr gtv 'git tag | sort -V'

# update-index (mark files as not changed, i.e. font size settings in zed settings.json file, or vscode settings.json)
abbr gassume 'git update-index --assume-unchanged'
abbr gassumeun 'git update-index --no-assume-unchanged'
abbr gassumels 'git ls-files -v | grep ^h'
# TODO are there other letter/status prefixes besides 'h' that apply to assume-unchanged files? they would be lowercase btw, if so

# whatchanged (logs)
abbr gwch 'git whatchanged -p --abbrev-commit --pretty=medium'

## diff
# * what happened to my usage of diff-so-fancy vs gdcw/gdw ... for some reason I wanted to use dsf instead but then had issues w/ it IIRC in windows/wsl so I gah... just look into this again if it becomes a hassle here
abbr gd "git diff --color-words"
abbr gdc "git diff --cached --color-words"
abbr kgdc "git diff --cached" # common typo alias (cmd+k clear => kgst)
# last commit diff:
abbr gdlf 'git diff-tree -r HEAD~1 HEAD'
#
abbr dsf 'diff-so-fancy'

## LFS
#
abbr lfs "git lfs"
abbr lfsi "git lfs install"
abbr lfsls "git lfs ls-files"
abbr lfsm "git lfs migrate"
abbr lfspr "git lfs prune"
abbr lfsst "git lfs status"
abbr lfst "git lfs track '*.EXT'"
abbr lfsup "git lfs update"
abbr lfsut "git lfs untrack '*.EXT'"
abbr lfsv "git lfs version"
