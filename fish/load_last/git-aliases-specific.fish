# - w/ message
abbr --set-cursor='!' gcmsg 'git commit -m "!"'
abbr --set-cursor='!' gcam 'git commit -a -m "!"'


abbr --set-cursor='!' yolo 'git commit --all -m "!" && git push'

# TODO why do I need _glX? isn't regex doing the same thing => read docs on why
abbr --regex 'gl\d+' --function glX _glX
function glX
    string replace --regex '^gl' 'git log -' $argv
end

set _unpushed_commits "HEAD@{push}~1..HEAD" # always show last pushed commit too (so if nothing unpushed the output isn't empty as if maybe broken)
set _unpushed_commits_without_last_pushed "HEAD@{push}..HEAD" # in some cases I don't wanna show last pushed (i.e. gls --stat)
abbr gst 'git status'
abbr gsl "git status && echo && git_unpushed_commits" # * try # FYI requires gst/glo aliases(funcs) to work
abbr glo git_unpushed_commits # composed by gsl
abbr gup git_unpushed_commits
function git_unpushed_commits --description "(g)it (u)n(p)ushed commits"
    # think `glo` that also works w/o remotes (currently glo blows up w/o remotes)
    # PRN port to pwsh and zsh

    # has remotes:
    if git rev-parse --abbrev-ref --symbolic-full-name @{upstream} &>/dev/null
        git log $_unpushed_commits
        return
    end

    # has reviewed branch:
    if git rev-parse --verify reviewed >/dev/null 2>&1
        # PRN do I even like this idea?
        git log reviewed~1..HEAD
        return
    end

    # show last X commits:
    git log -10 # s/b slightly annoying to remind me that I don't have a point of reference for the most recent of commits (ie unpushed/reviewed)
    log_ --red "WARN: missing both upstream and/or reviewed branch"
end
#
# w/ patch (diff)
abbr glp "git log --patch $_unpushed_commits"
abbr --regex 'glp\d+' --function glpX _glpX
function glpX
    string replace --regex '^glp' 'git log --patch -' $argv
end
#
# w/ stat (files)
abbr gls "git log --stat $_unpushed_commits_without_last_pushed"
abbr --regex 'gls\d+' --function glsX _glsX
function glsX
    string replace --regex '^gls' 'git log --stat -' $argv
end
#
# graph
abbr glg "git log --graph $_unpushed_commits"

# tracked branch
function git_current_branch
    git rev-parse --abbrev-ref HEAD
end
abbr ggsup 'git branch --set-upstream-to=origin/$(git_current_branch)'

# diff
abbr gdlc "git log --patch --color-words HEAD~1..HEAD"
abbr --regex 'gdlc\d+' --function gdlcX _gdlcX
function gdlcX
    set -l num (string replace --regex '^gdlc' '' $argv)
    set -l prev (math $num - 1)
    echo "git log --patch --color-words HEAD~$num..HEAD~$prev"
end

# VCS in general:
function pwd --description "pwd for a repository => repo root in yellow + repo dir in white"
    # if this causes grief, go back to just prd
    if not isatty stdout
        builtin pwd $argv
        return
    end
    # PRN support -P/-L arg like builtin does, and set default behavior of not resolving symlinks (-L) because right now the below defaults as if -P was passed (it resolves symlinks)
    set _rr (_repo_root)
    set _prefix (git rev-parse --show-prefix 2>/dev/null)
    if string match -q -r '(?<host_dir>.*/(bitbucket|github|gitlab))/(?<repo>.*)' $_rr
        # path is normal color thru host dir (i.e. ~/repos/github), then cyan for org/repo, then white for the repo dir(s)
        echo -s (set_color normal) $host_dir / \
            (set_color cyan) $repo \
            (set_color --bold white) / $_prefix \
            (set_color normal)
    else
        # else path is normal through repo root and white for the repo dir(s)
        echo -s (set_color normal) $_rr \
            (set_color --bold white) / $_prefix \
            (set_color normal)
    end
    # PRN I like leaving white / on end of path but builtin for pwd doesn't include the final slash, I like it right now b/c it makes it clear that it is the root of a repo
end

function prd --description "print repo dir (pwd relative to repo root)"
    # recreate prd
    echo -s (set_color --bold white) \
        (git rev-parse --show-prefix 2>/dev/null) \
        (set_color normal)
end

abbr rr _repo_root
function _repo_root

    # FYI missing git command should break returning a path
    if not command -q git
        echo "[FAIL] git not found" >&2
        return 1
    end

    if git rev-parse --is-inside-work-tree 2>/dev/null 1>/dev/null
        git rev-parse --show-toplevel 2>/dev/null
    else if command -q hg && hg root 2>/dev/null 1>/dev/null
        # FYI don't let missing hg command break machines w/o hg repos
        hg root 2>/dev/null
    else
        builtin pwd
    end

end


## bootstrap git helpers
#

# high level status of both repos:
function dotgst
    _dot_both status
end
function dotgsl --description "gst; glo"
    # * PREFER this long term will save time!
    dotglo
    log_blankline
    dotgst
end
function dotglo --description "log HEAD@{push}~1..HEAD"
    # ok to leave old glo here instead of git_unpushed_commits b/c I always have pushed commits for the two repos I use this for
    _dot_both log HEAD@{push}~1..HEAD
end

# workflow: dotgap => dotgsl => dotgcm => dotgp
function dotgaa --description "add --all"
    _dot_both add --all
end
function dotgap --description "add --patch"
    _dot_both add --patch
end
function dotgrp --description "restore --patch"
    _dot_both restore --patch
end

function dotgcm --description "commit staged changes w/ message"

    # ensure message is provided:
    argparse --min 1 -- $argv || return 1
    set --local message $argv

    # commit staged changes
    git -C $WES_DOTFILES commit -m $message
    git -C $WES_BOOTSTRAP add subs/dotfiles # after committing dotfiles, add the commit change to bootstrap (super module)
    git -C $WES_BOOTSTRAP commit -m $message
end

function dotgp --description push
    _dot_both push
end
function dotgl --description pull
    _dot_both pull
end

function dotgrsh --description "reset --soft HEAD~1"
    _dot_both reset --soft HEAD~1
end

function dotgdlc --description "log --patch HEAD~1..HEAD"
    _dot_both log --patch --color-words HEAD~1..HEAD
end

# expand `dotglX` => `dotgl -X`
abbr --add dotglX --regex 'dotgl\d+' --function dotglX
function dotglX
    string replace --regex '^dotgl' 'dotgl -' $argv
end
function dotgl --description "log -X"
    _dot_both log $argv
end

function dotgdc --description "diff --cached"
    _dot_both diff --cached --color-words
end

function dotgd --description diff
    _dot_both diff --color-words
end

function _dot_both
    set -l cmd $argv

    log_header "DOTFILES:"
    PAGER= git -C $WES_DOTFILES $cmd

    log_blankline
    log_header "BOOTSTRAP:"
    PAGER= git -C $WES_BOOTSTRAP $cmd
end
# PRN gcan! to modify both?! if I feel that I need this
