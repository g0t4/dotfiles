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

# # # diff
# # ealias gdlc="git log --patch HEAD~1..HEAD"
# # ealias gdlc1="gdlc"
# # for i in {2..10}; do ealias "gdlc$i"="git log --patch HEAD~$i..HEAD~$(($i - 1))"; done # !FISHISSUE abbr+regex!

# # # VCS in general:
# # ealias rr='_repo_root'
# # # prd = print repo directoy ;) (like pwd)
# # alias prd='echo $(rr)' # don't expand this alias! it just returns a path
# # function _repo_root() {
# #   if git rev-parse --is-inside-work-tree 2>/dev/null  1>/dev/null; then
# #     git rev-parse --show-toplevel 2>/dev/null
# #   elif hg root 2>/dev/null  1>/dev/null; then
# #     hg root 2>/dev/null
# #   else
# #     pwd
# #   fi
# # }
