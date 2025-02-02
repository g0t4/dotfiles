ealias g 'git'

# ignored
ealias gsi 'git status --ignored'
ealias gwhatsignored 'git ls-files --others --directory --no-empty-directory; echo NOTE: gsa works too'

# reset
ealias grhh 'git reset --hard HEAD'
ealias grsh 'git reset --soft HEAD~1'

# reflog
ealias grl 'git reflog'
ealias grla 'git reflog --all'

# restore (staged)
abbr grst 'git restore --staged' # TBD do I wanna default for entire repo? or force myself to remember grstr instead?
abbr grstp 'git restore --staged --patch' # ! USE THIS MORE OFTEN (maybe make it grst?)
abbr grstr 'git restore --staged "$(_repo_root)"' # use $() syntax for compat w/ zsh too
#
# restore (unstaged)
abbr grp 'git restore --patch' # * favorite
abbr grss 'git restore --source'


# add `ga`
ealias ga "git add"
ealias gav "git add --verbose"
ealias gaa "git add --all"
ealias gau 'git add --update' # only changed files (not untracked)
ealias gap "git add --patch" # ~= git add --interactive => (p)atch on all modified files
ealias gai "git add --interactive"

# remotes
ealias grv 'git remote -v'

# branches
ealias gba 'git branch --all -vv'
ealias gbr 'git branch --remote -vv'


# gcmark like
abbr review "git commit -a -m 'review'"
abbr notes "git commit -a -m 'notes'"
# abbr gcsubs "git commit -a -m 'subs'; git push; git diff --color-words HEAD~1 HEAD"
# new commit:
ealias gcv 'git commit -v' # `gc` reserved in posh
ealias gca 'git commit -v -a'
# start the quoted message
ealias gcmsg 'git commit -m "' -NoSpaceAfter # don't use gcm (Get-Command)
ealias gcam 'git commit -a -m "' -NoSpaceAfter
# amend:
ealias gc! 'git commit -v --amend'
ealias gcn! 'git commit -v --no-edit --amend'
ealias gca! 'git commit -v -a --amend'
ealias gcan! 'git commit -v -a --no-edit --amend'

# checkout
ealias gco 'git checkout'
ealias gcom 'git checkout master'
ealias gcop 'git restore --patch' # ! interactive checkout
ealias gcob 'git checkout -b'

# diff
# on windows I don't have diff-so-fancy to help with diffs so I want to default to use --color-words to make diffs readable
ealias gd 'git diff --color-words'
# ealias gdw 'git diff --color-words' # add back if muscle memory from mac but otherwise is same as gd
ealias gdc 'git diff --cached --color-words'
ealias kgdc 'git diff --cached --color-words' # common typo alias (cmd+k clear > kgst)
# ealias gdcw 'git diff --cached --color-words'

# TODO resolve conflicting gdt
ealias gdt 'git describe --tags `git rev-list --tags --max-count=1`'
# ealias gdt 'git diff-tree --no-commit-id --name-only -r'

ealias gdlc 'git diff --color-words HEAD~1 HEAD'
#ealias gdlc1 --color-words 'git diff HEAD~2 HEAD~1'
#ealias gdlc2 --color-words 'git diff HEAD~3 HEAD~2'
1..50 | ForEach-Object {
    ealias "gdlc$_" "git diff --color-words HEAD~$($_+1) HEAD~$_"
}

# Show changes in last commit by diffing with previous commit

# LOGS
ealias glf "git log" # used to inline format
1..10 | ForEach-Object { ealias "gl$_" "git log -$_" } # last N commits
#
$_unpushed_commits="'HEAD@{push}~1..HEAD'"
ealias glo "git log ${_unpushed_commits}"
ealias glp "git log --patch ${_unpushed_commits}" # include patch (diff)
1..10 | ForEach-Object { ealias "glp$_" "git log --patch -$_" } # last N commits
ealias gls "git log --stat ${_unpushed_commits}" # include patch (diff)
1..10 | ForEach-Object { ealias "gls$_" "git log --stat -$_" } # last N commits
ealias glg "git log --graph ${_unpushed_commits}" # graph of changes

## status
ealias gst "git status"
# FYI gsl below
ealias kgst "git status" # common typo alias (cmd+k clear > kgst)
ealias gss "git status -s"
ealias gsb "git status -sb"
ealias gsu "git status --untracked-files"
function gsl(){
    # in this case I want no color to distract in the output so no log methods centrally that might change... this is custom to the need to quickly see git repo changes
    $_gst=(get-alias gst).Definition
    Invoke-Expression $_gst
    Log_BlankLine
    $_glo=(get-alias glo).Definition
    Invoke-Expression $_glo
}


## fetch
ealias gf 'git fetch'
ealias gfa "git fetch --all --prune --jobs 10"
ealias gfo 'git fetch origin'

## pull
ealias gl "git pull"
ealias glr "git pull --recurse-submodules" # keep separate alias for now as its time consuming to pull multiple submodules

## push
ealias gp 'git push'
ealias gpd 'git push --dry-run'
ealias gpf 'git push --force-with-lease'
ealias gpf! 'git push --force'
# ealias gpoat 'git push origin --all && git push origin --tags'
ealias gpu 'git push upstream'
# gpv is internal alias # ealias gpv 'git push -v'
ealias gpsup 'git push --set-upstream origin $(git_current_branch)'

## submodules
# alias pattern: (g)it (s)ub(m)odule (c)ommand
ealias gsm 'git submodule'
ealias gsmi 'git submodule init'
ealias gsmu 'git submodule update --remote --recursive'
ealias gsmst 'git submodule status --recursive'
# add
# summary
ealias gsme 'git foreach' # for(e)ach

function git_current_branch() {
    git rev-parse --symbolic-full-name HEAD
}

Set-Alias grr git_repo_root
function git_repo_root() {
    # ! PRN > add hg root support like on zsh equivalent of _repo_root (not just _git_repo_root)
    # git returns / which breaks some windows tools that only support backslashes (ie explorer)
    $path=git rev-parse --show-toplevel
    if(!$path){
        return $null
    }
    return Convert-Path "$path"
}

ealias gcl 'git clone --recurse-submodules'

ealias gbl 'git blame -b -w'


ealias gclean 'git clean -fd'

ealias 'gcan!' 'git commit -v -a --no-edit --amend'

# todo - ealias - left off at gl* on zsh aliases list for git
