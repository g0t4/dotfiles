# - w/ message
abbr --set-cursor='!' gcmsg 'git commit -m "!"'
abbr --set-cursor='!' gcam 'git commit -a -m "!"'


ealias glf='git log'

# # for i in {1..10}; do ealias gl$i="git log -$i"; done # last N commits # !FISHISSUE => use abbr + regex + func to expand this to any number and not need a loop! # split zsh specific loop out and keep in zsh files only
# # abbr --regex 'gl\d+' --function glX
# # function glX
# #   string replace --regex '^gl' 'git log -' $argv
# # end

# # #
# # local _unpushed_commits="HEAD@{push}~1..HEAD"
# # ealias glo="git log ${_unpushed_commits}"
# # ealias glp="git log --patch ${_unpushed_commits}" # include patch (diff)
# # for i in {1..10}; do ealias glp$i="git log --patch -$i"; done # last N commits # !FISHISSUE abbr+regex!
# # ealias gls="git log --stat ${_unpushed_commits}" # summary of file changes
# # for i in {1..10}; do ealias gls$i="git log --stat -$i"; done # last N commits # !FISHISSUE abbr+regex!
# # ealias glg="git log --graph ${_unpushed_commits}" # graph of changes

# # # tracked branch
# # function git_current_branch() {
# #   # ! can this be rewritten to be interop w/ fish and zsh?
# #   git rev-parse --abbrev-ref HEAD
# # }
# # ealias ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'

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
