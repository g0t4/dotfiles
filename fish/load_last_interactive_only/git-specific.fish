# grvcp (copy remote url)
abbr --add grvcp --function _grvcp
function _grvcp
    set -l first_remote $(git remote | head -n 1)

    # 1. expand into "git remote get-url $first_remote | pbcopy" so user can see the REMOTE NAME (and change it if need be?)

    # 2. expand into "echo https://... | pbcopy" so user can see the URL
    #echo "echo $(git remote get-url $first_remote) | pbcopy"

    # 3. or BOTH :)
    echo "git remote get-url $first_remote | pbcopy # $(git remote get-url $first_remote)"

    # 4. OR copy all remotes?

    # most of the time there is one remote so lets not overcomplicate it... pick one and use it until it rubs the wrong way
end

function mark
    # for review commits that I don't need to step by step commit, instead just make a commit of all changes and dump the diff for my optional review
    git diff HEAD
    git add . # assumes no other work, but yeah I'm calling this explicitly
    git commit -m mark-review
    git status
end

# - w/ message
abbr --set-cursor gcmsg 'git commit -m "%"'
abbr --set-cursor gcam 'git commit -a -m "%"'

abbr --set-cursor yolo 'git commit --all -m "%" && git push'

# * git push
# push up to the last X commits, IOTW all but the last X commits
abbr --regex 'gpupto\d+' --function gpuptoX _gpuptoX
function gpuptoX
    set -l num (string replace --regex '^gpupto' '' $argv)
    # refspec has object:dest_ref
    # TODO also use default remote? or?
    echo "git push origin HEAD~$num:$(git_current_branch)"
end

abbr gl git log

abbr --regex 'gl\d+' --function glX _glX
abbr --regex 'g\d+' --function glX _gX
function glX
    # support both
    #   gl10
    #   g10
    #   hence l? => optional l after the g
    string replace --regex '^gl?' 'git log -' $argv
end

set _unpushed_commits "HEAD@{push}~1..HEAD" # always show last pushed commit too (so if nothing unpushed the output isn't empty as if maybe broken)
set _unpushed_commits_without_last_pushed "HEAD@{push}..HEAD" # in some cases I don't wanna show last pushed (i.e. gls --stat)
#
abbr gs 'git status' # this is perhaps my most frequently used abbr, shortened from gst... see if gs feels materially easier to type, especially quickly
reminder_abbr_remapped gst gs
#
abbr gstl "git status && echo && git_unpushed_commits" # * try # FYI requires gst/glo aliases(funcs) to work

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
function git_current_branch_upstream
    # this is the value you set with:
    #   git branch --set-upstream-to=origin/<branch>
    git rev-parse --abbrev-ref --symbolic-full-name @{upstream}
    # PRN use this to figure out the upstream remote name, i.e. if gpuptoX is not to remote named 'origin'
end
abbr ggsup 'git branch --set-upstream-to=origin/$(git_current_branch)'

# * diff
# FYI no way to tab complete --command git so just leave it top level for complettion's sake
# TODO submit a PR w/ a fix for completions of --position=anywhere and --command abbrs?
# FYI I put git on front so I can jump to git in my commandline and type copy<TAB> and bam it completes
# or del<TAB> and it goes
abbr -- git_delta_copyable "git -c delta.side-by-side=false -c delta.line-numbers=false"
abbr -- git_delta_side_by_side "git -c delta.side-by-side=true"
abbr -- git_delta_unified "git -c delta.side-by-side=false"
abbr -- git_delta_no_line_numbers "git -c delta.line-numbers=false"
#
abbr gdlc "git log --patch HEAD~1..HEAD"
abbr gdlcu "git -c delta.side-by-side=false log --patch HEAD~1..HEAD"
abbr --regex 'gdlc[u]?\d+' --function gdlcX _gdlcX
function gdlcX
    echo -n git
    if string match --quiet --regex '^gdlcu' $argv
        # u == unified (not side by side) diff
        echo -n " delta.side-by-side=false "
    end
    set -l num (string replace --regex '^gdlc[u]?' '' $argv)
    set -l prev (math $num - 1)
    echo " log --patch HEAD~$num..HEAD~$prev"
end
#
# gds - one list of files changed across range of commits
#   vs gls - which is per commit
abbr gds "git diff --stat $_unpushed_commits_without_last_pushed"
abbr --regex 'gds\d+' --function gdsX _gdsX
function gdsX
    # too bad `git diff -X` doesn't exist (submit a PR?)
    #   instead have to set start/stop commit refs
    echo -n (string replace --regex '^gds' 'git diff --stat HEAD~' $argv)'..HEAD'
end

abbr --set-cursor glgrep 'git log --grep="%"'

# WIP => disable pager and color for generating a unified diff
abbr gd_patch "git --no-pager diff --no-color"

# VCS in general:
if status is-interactive
    function pwd --description "pwd for a repository => repo root in yellow + repo dir in white"
        # if this causes grief, go back to just prd
        if not isatty stdout
            builtin pwd $argv
            return
        end
        # PRN support -P/-L arg like builtin does, and set default behavior of not resolving symlinks (-L) because right now the below defaults as if -P was passed (it resolves symlinks)

        if test (builtin pwd) = /
            # at root of fs, don't show // # TODO come back and rework below to drop the trailing / as I don't think I like that differing vs pwd.. especially b/c I do demos with this and the color is fine but less so altering the path even if the same.. NBD but might as well be consistent
            echo -s (set_color normal) /
            return
        end
        _pwd
    end
end

function _pwd

    # FYI test w/ split pane in iterm2 (open lots of example paths, /, ~/, in a github repo, in nested repo dir) => use broadcast Cmd+Shift+I and send Cmd+K => pwd => command pwd  # compare results
    set _rr (_repo_root)

    # prefix w/in repo (beneat repo root), prepend / for join logic below to avoid trailing / in final output (so pwd matches command pwd)
    set _prefix "/"(git rev-parse --show-prefix 2>/dev/null)
    set -l _prefix (string replace -r '/$' '' $_prefix) # strip trailing / from rev-parse (or if in repo root, from prepended / which is also trailing)

    if string match -q -r '(?<host_dir>.*/(bitbucket|github|gitlab))/(?<repo>.*)' $_rr
        # path is normal color thru host dir (i.e. ~/repos/github), then cyan for org/repo, then white for the repo dir(s)
        echo -s (set_color normal) $host_dir / \
            (set_color cyan) $repo \
            (set_color yellow) $_prefix \
            (set_color normal)
    else
        # else path is normal through repo root and white for the repo dir(s)
        echo -s (set_color normal) $_rr \
            (set_color yellow) $_prefix \
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

# *** worktrees (finally using these - linked worktrees, not just main worktree)
abbr gwt "git worktree"
abbr gwtls "git worktree list"
abbr gwta "git worktree add"
abbr gwtab "git worktree add -b" # create new branch (use -B to clobber if exists)
abbr gwtrm "git worktree remove"
abbr gwtm "git worktree move"
# lock/unlock => wait until I use those

# rebasing
abbr grb 'git rebase'
abbr grba 'git rebase --abort'
abbr grbc 'git rebase --continue'
abbr grbs 'git rebase --skip'
abbr grbi 'git rebase -i'
abbr grbias 'git rebase -i --autostash'
#
abbr --add _grbi_d --regex 'grbi\d+' --function _abbr_expand_grbi_d
function _abbr_expand_grbi_d
    string replace --regex "grbi(\d+)" "git rebase -i HEAD~\1" $argv[1]
end

# * stash
# FYI can do gstashl<TAB> or gashl<TAB>
abbr gstash 'git stash'
abbr gstash_list 'git stash list'
#
abbr gstash_show 'git stash show --text 0' # 0 as reminder that you can pass any index number instead of stash@{1} etc
# --text makes it show the diff vs a stat of files
#
abbr gstash_drop 'git stash drop 0'
abbr gstash_pop 'git stash pop 0'
abbr gstash_apply 'git stash apply'
abbr gstash_branch 'git stash branch'
abbr gstash_patch 'git stash push --patch --no-keep-index' # *** pick what to stash!!! easily make multiple stash commits too!
# TODO do I like --no-keep-index w/ --patch? w/o this it seems to keep changes in the index which can be oddly confusing too
abbr --set-cursor gstash_push 'git stash push --message "%"'
abbr --set-cursor gstash_save 'git stash push --message "%"' # save is deprecated, use push (I still use save all the time so this will help me transition)
abbr gstash_clear 'git stash clear'
# abbr gstash_create 'git stash create' # for scripts
# abbr gstash_store 'git stash store' # for scripts
#
# abbr gstash_untracked_too 'git stash --include-untracked'

# * licenses

function _get_license
    if test -n "$(git status --porcelain)"
        echo "Repository has uncommitted changes, aborting..."
        return
    end

    set url $argv[1]
    set dest "LICENSE.txt"
    curl -fsSL $url -o $dest
    # check if repo is dirty
    git add LICENSE.txt
    git commit -m "Add LICENSE.txt"
end

function get_license_DWTFYW
    # NOTE this is based on, but is not exactly the "DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE"
    _get_license "https://raw.githubusercontent.com/g0t4/dotfiles/master/LICENSE.txt"
end

function get_license_MIT0
    _get_license "https://raw.githubusercontent.com/aws/mit-0/refs/heads/master/MIT-0"
end
