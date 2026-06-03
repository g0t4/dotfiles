# Note: alias collisions to avoid:
# `go*` for `go` commands
# `grep` for default grep params
# `gi*` for my git ignore customizations
# `globurl`

# status
abbr gsts 'git status -s'
abbr gstb 'git status -sb'
abbr gstu 'git status --untracked-files'
# optionally replace . with a dir or path in the repo:
abbr gsti 'git status --ignored .'
# FYI ok to replace `.` with a dir or path in the repo to limit search
# look for legit, ignored files (i.e. sensitive log captures) sans the ones I never care about:
# look at untracked and/or ignored files.. and skip things I know I never care bout
abbr gstiv --set-cursor 'git status --ignored --untracked-files --short ".%" | rg_grep -i -v "node_modules|\.venv/|\.rag/|__pycache__|DS_Store|\.pytest_cache/|/bin/|/obj/|/target/|iterm2env/|egg-info/|dist/"'
# also skip image files (don't always do this, hence a separte abbr)
abbr gstiv_all --set-cursor 'git status --ignored --untracked-files --short ".%" | rg_grep -i -v "node_modules|\.venv/|\.rag/|__pycache__|DS_Store|\.pytest_cache/|/bin/|/obj/|/target/|iterm2env/|egg-info/|dist/|.*\.(png|bmp|jpg|svg)\$"'

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
abbr grl 'git reflog --pretty=reflog'
abbr grla 'git reflog --all --pretty=reflog'

# add
abbr ga 'git add'
abbr 'ga.' 'git add .'
abbr 'ga..' 'git add ..'
abbr gav 'git add --verbose' # verbosity in what is added
abbr gaa 'git add --all'
abbr gaaa 'git add --all' # common typo
abbr gau 'git add --update' # don't add new files, just changed files (either already indexed or head?)
abbr gap 'git add --patch' # * favorite # patch = interactive, but skips first menu and goes right to patch
abbr gai 'git add --interactive' # patch but w/ initial menu

# branch read:
# don't use pager on git branch (read commands)
abbr gb 'git branch'
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
# FYI pwsh has many builtin aliases stating with 'g' b/c Get :)
#   gcm = Get-Command, gc = Get-Content
# commit
# FYI go back to -v on all of these git commit abbrs if I get rid of my git-commit-with-function-context
abbr gc 'GIT_EDITOR=git-commit-with-function-context git commit' # FYI gc=Get-Content in powershell (I am very tempted to overwrite it!) ... I always want a gc command and struggle to find it
abbr gca 'GIT_EDITOR=git-commit-with-function-context git commit -a'
# - amend
abbr gc! 'GIT_EDITOR=git-commit-with-function-context git commit --amend'
abbr gcn! 'git commit --no-edit --amend'
abbr gca! 'GIT_EDITOR=git-commit-with-function-context git commit -a --amend'
abbr gcan! 'git commit -a --no-edit --amend'

# checkout
abbr gco 'git checkout'
abbr gcom 'git checkout master'
abbr gcop 'git restore --patch' # interactive restore (like git add --patch) - FYI prefer git restore over git checkout
abbr gcob 'git checkout -b'

# I'm always flumoxed to find the scope of config options to edit with confidence
abbr gconf 'grc git config --list --show-origin --show-scope' # show files where set (ie scope's file)
abbr gnoconf 'env GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null grc git config --list --show-origin --show-scope' # show files where set (ie scope's file)
abbr gnoconf_export 'export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null' # show files where set (ie scope's file)
#  FYI alternative is GIT_CONFIG_NOSYSTEM but /dev/null seems fine above...  though I don't have system level config (yet?)

# clone
abbr gcl 'git clone --recurse-submodules'
abbr gcl_no_lfs 'GIT_LFS_SKIP_SMUDGE=1 git clone --recurse-submodules'
abbr wcl_no_lfs 'GIT_LFS_SKIP_SMUDGE=1 wcl'

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
abbr gpl 'git pull'
abbr gplas "git pull --autostash"
abbr gplr 'git pull --recurse-submodules' # keep separate alias for now as its time consuming to pull multiple submodules
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
abbr --add _grev_d --regex 'grev\d+' --function _abbr_expand_grev_d
function _abbr_expand_grev_d
    string replace --regex '^grev' 'git revert HEAD~' $argv
end

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

# rev-parse (consider adding the following, except that you have helpers that basically do these two:)
# abbr -- grevp 'git rev-parse --show-toplevel' # repo_root does this
# abbr -- grevp_prefix 'git rev-parse --show-prefix' # prd does this

# show
abbr gsh 'git show' # --color-words if not using external diff
abbr gsps 'git show --pretty=short --show-signature' # --color-words if not using external diff

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

# switching branches
abbr gsw 'git switch'
abbr gswc 'git switch -c'

# tagging
abbr gts 'git tag -s'
abbr gtv 'git tag | sort -V'

# update-index (mark files as not changed, i.e. font size settings in zed settings.json file, or vscode settings.json)
abbr gassume 'git update-index --assume-unchanged'
abbr gassumeun 'git update-index --no-assume-unchanged'
abbr gassumels 'git ls-files -v | rg_grep ^h'
# TODO are there other letter/status prefixes besides 'h' that apply to assume-unchanged files? they would be lowercase btw, if so

# whatchanged (logs)
abbr gwch 'git whatchanged -p --abbrev-commit --pretty=medium'

## diff
# * --color-words fubar's delta diffs (let delta handle the styling)
# makes me wonder if this was also what I was hating about diff-so-fancy
abbr gd "git diff" # show unstaged (worktree) changes
abbr gd_summary "git diff --summary" # --summary shows % similarity but squelches diff
abbr gd_worktree "git diff" # show worktree changes
#
abbr gdc "git diff --staged"
abbr gdc_summary "git diff --staged --summary" # --summary will show rename % similarity but squelches diff
abbr gd_index "git diff --staged" # show staged (index) changes
#
abbr gd_is_worktree_clean "git diff --quiet" # 0 = worktree is clean (no unstaged changes), 1 = worktree is dirty
abbr gd_is_index_clean "git diff --staged --quiet" # 0 = index is clean (no staged changes), 1 = index is dirty
# last commit diff:
abbr gdlf 'git diff-tree -r HEAD~1 HEAD'
#
abbr dsf diff-so-fancy

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
abbr --set-cursor -- gcmsg 'git commit -m "%"'
abbr --set-cursor -- gcam 'git commit -a -m "%"'

# git command specific abbrs (FYI cannot do subcommand specific... so no `git commit` specific)
abbr --command git --position anywhere -- gptoss '--author "gptoss120b<wes.mcclure+gptoss120b@gmail.com>"'
abbr --command git --position anywhere -- qwen3 '--author "qwen3.6-35b-a3b<wes.mcclure+qwen3.6-35b-a3b@gmail.com>"'

# joke:
abbr --set-cursor -- yolo 'git commit --all -m "%" && git push'

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
abbr gst 'git status' # I just can't stop using gst...
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
abbr glp "git log --patch $_unpunched_commits"
abbr glpf "git log --pretty=full --patch $_unpunched_commits"
abbr --regex 'glpf?\d+' --function glp_x _glp_x
function glp_x
    set command_line $argv[1]
    if string match --quiet --regex '^glpf' $command_line
        string replace --regex '^glpf' 'git log --pretty=full --patch -' $command_line
    else
        string replace --regex '^glp' 'git log --patch -' $command_line
    end
end

#
# w/ stat (files)
abbr gls "git log --stat $_unpushed_commits_without_last_pushed"
abbr glsf "git log --pretty=full --stat $_unpushed_commits_without_last_pushed"
abbr --regex 'gls[f]{0,1}\d+' --function glsX _glsX
function glsX
    # btw f is optional and => --pretty=full if present
    set expanded (string replace --regex '^glsf' 'git log --pretty=full --stat -' $argv); or true # swap most specific first
    string replace --regex '^gls' 'git log --stat -' $expanded; or true # swap least specific second and echo
    # or true else failed command kills expansion... ignore failures
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
# TODO figure out what I want for helpers (probably want to habituate a shortened form of one of these)
#   FYI entire motive is for when I am extracting a function and the space is changing...
#   if I do it all in one go then the diff (on longer functions) is unintelligible...
#   so I will break down commits to smaller steps so I can review that step one was ONLY adding one level of indent...
#      this --ignore-space-change shows me indeed I did not change any code beyond the indent
#      once I know that then b/c it is committed I can safely move to changing the code and diffs will look good (small)
#        i.e. add new function signature
#             call new function
#             wrangle params (add/remove params, inline/extract variables/params)
#             each of these as separate commits makes review simple and much more bullet proof
#      SO, sometimes I know it is just whitespace that I want to check for.. that's where these helpers come in
#        b/c otherwise diff tools blow diahhreha when indentation is mixed with code changes
#        many tools suck with just indent changes _ALONE_ (i.e. delta, hunk)
#        so I do my review and forget about indent...
#        OH and another route is to save indent for last step
#        YES broken code along the way, who cares!
#
abbr -- git_ignore_space_changes "git diff --ignore-space-change"
abbr -- git_ignore_all_space "git diff --ignore-all-space"
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
# gd_stat - single list of files ACROSS range of commits
#   vs gls (git log --stat) which is PER commit
abbr gd_stat "git diff --stat $_unpushed_commits_without_last_pushed"

# * hunkdiff (recommended by @mitchelh)
function hunkdiff
    # PRN? or do I want:
    # `abbr hunkdiff npx hunkdiff`
    npx hunkdiff $argv
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

function _repo_is_index_clean
    set repo_dir $argv[1]
    set -q argv[1]; or set repo_dir (_repo_root)

    # 0 = nothing staged, 1 = staged
    git -C $repo_dir diff --staged --quiet
end

function _repo_is_worktree_clean
    set repo_dir $argv[1]
    set -q argv[1]; or set repo_dir (_repo_root)

    git -C $repo_dir diff --quiet
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

# gapN: git add --patch with diff.context set to N (e.g., gap10 => diff.context=10)
abbr --regex 'gap\d*' --function gapX _gapX
function gapX
    # Extract the numeric suffix
    set -l num (string replace --regex '^gap' '' $argv)
    if test -z "$num"
        echo "git add --patch"
        return
    end
    echo "git -c diff.context=$num add --patch"
end

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
