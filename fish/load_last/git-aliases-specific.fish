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
ealias gdlc="git log --patch HEAD~1..HEAD"
abbr --regex 'gdlc\d+' --function gdlcX _gdlcX
function gdlcX
    set -l num (string replace --regex '^gdlc' '' $argv)
    set -l prev (math $num - 1)
    echo "git log --patch HEAD~$num..HEAD~$prev"
end

# VCS in general:
ealias rr='_repo_root'
alias rr='_repo_root' # ! first issue, abbreviations aren't expanded during command evaluation (or is there an arg for it?) so I have to define it twice if I wanna use it elsewhere... probably should just use _repo_root elsewhere but I use $(rr) often in other aliases so lets be safe
# prd = print repo directoy ;) (like pwd)
ealias prd='_repo_root'
function _repo_root

    if git rev-parse --is-inside-work-tree 2>/dev/null 1>/dev/null
        git rev-parse --show-toplevel 2>/dev/null
    else if hg root 2>/dev/null 1>/dev/null
        hg root 2>/dev/null
    else
        pwd
    end

end

## bootstrap git helpers (WIP, not sure what these will settle into just yet)
# ? rewrite as `dotfiles gst/gcmsg/etc` and repeat command in both spots! would need to define -g aliases (yucky)
function gstdotfiles

    log_info "git status of dotfiles:"
    git -C $WES_DOTFILES status

    log_blankline
    log_info "git status of bootstrap:"
    git -C $WES_BOOTSTRAP status

    cd $WES_DOTFILES
end

function gcmdotfiles --description "blind commit w/ message to bootstrap and dotfiles"
    set --local message $argv
    git -C $WES_DOTFILES commit -a -m $message
    git -C $WES_BOOTSTRAP commit -a -m $message
end

function gpdotfiles --description "push dotfiles and bootstrap"
    git -C $WES_DOTFILES push
    git -C $WES_BOOTSTRAP push
end

function dotglo
    log_info "dotfiles:"
    git -C $WES_DOTFILES log HEAD@{push}~1..HEAD

    log_blankline
    log_info "bootstrap:"
    git -C $WES_BOOTSTRAP log HEAD@{push}~1..HEAD

end

function dotgdlc

    log_info "dotfiles:"
    PAGER=none git -C $WES_DOTFILES log --patch HEAD~1..HEAD

    log_blankline
    log_info "bootstrap:"
    PAGER=none git -C $WES_BOOTSTRAP log --patch HEAD~1..HEAD

end

# PRN gcan! to modify both?! if I feel that I need this
