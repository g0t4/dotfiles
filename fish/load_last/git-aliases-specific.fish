# - w/ message
abbr --set-cursor='!' gcmsg 'git commit -m "!"'
abbr --set-cursor='!' gcam 'git commit -a -m "!"'


# TODO why do I need _glX? isn't regex doing the same thing => read docs on why
abbr --regex 'gl\d+' --function glX _glX
function glX
    string replace --regex '^gl' 'git log -' $argv
end

set -l _unpushed_commits "HEAD@{push}~1..HEAD"
ealias glo="git log $_unpushed_commits"
#
# w/ patch (diff)
ealias glp="git log --patch $_unpushed_commits"
abbr --regex 'glp\d+' --function glpX _glpX
function glpX
    string replace --regex '^glp' 'git log --patch -' $argv
end
#
# w/ stat (files)
ealias gls="git log --stat $_unpushed_commits"
abbr --regex 'gls\d+' --function glsX _glsX
function glsX
    string replace --regex '^gls' 'git log --stat -' $argv
end
#
# graph
ealias glg="git log --graph $_unpushed_commits"

# tracked branch
function git_current_branch
    git rev-parse --abbrev-ref HEAD
end
ealias ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'

# diff
ealias gdlc="git log --patch --color-words HEAD~1..HEAD"
abbr --regex 'gdlc\d+' --function gdlcX _gdlcX
function gdlcX
    set -l num (string replace --regex '^gdlc' '' $argv)
    set -l prev (math $num - 1)
    echo "git log --patch --color-words HEAD~$num..HEAD~$prev"
end

# VCS in general:
ealias rr='_repo_root'
alias rr='_repo_root' # ! first issue, abbreviations aren't expanded during command evaluation (or is there an arg for it?) so I have to define it twice if I wanna use it elsewhere... probably should just use _repo_root elsewhere but I use $(rr) often in other aliases so lets be safe
# prd = print repo directoy ;) (like pwd)
ealias pwdr='git rev-parse --show-prefix'

function prd --description "pwd for a repository => repo root in yellow + repo dir in white"
    set _rr (_repo_root)
    set _prefix (git rev-parse --show-prefix)
    echo -s $_rr (set_color --bold white) /$_prefix (set_color normal)
end

function _repo_root

    if git rev-parse --is-inside-work-tree 2>/dev/null 1>/dev/null
        git rev-parse --show-toplevel 2>/dev/null
    else if hg root 2>/dev/null 1>/dev/null
        hg root 2>/dev/null
    else
        pwd
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
