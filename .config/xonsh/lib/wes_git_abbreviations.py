"""Git abbreviations generated from fish/load_last_interactive_only/git.fish."""

from __future__ import annotations

import re

from wes_abbreviations import abbr
from wes_fish_bridge import fish_function


def _fish_abbreviation(function_name):
    def expand(context, _match):
        return fish_function(function_name, context.token)

    return expand


def register_git_abbreviations():
    abbr("-W", "--function-context", commands=("git", "diff"))
    abbr('man_gitrevisions', 'man gitrevisions')  # Fish line 25
    abbr(re.compile('reflog\\d+'), _fish_abbreviation('_abbr_expand_reflog_d'), position="anywhere")  # Fish line 30
    abbr('commit_with_message', ':/%', position="anywhere", cursor_marker="%")  # Fish line 35
    abbr('gsts', 'git status -s')  # Fish line 39
    abbr('gstb', 'git status -sb')  # Fish line 40
    abbr('gstu', 'git status --untracked-files')  # Fish line 41
    abbr('gsti', 'git status --ignored .')  # Fish line 43
    abbr('gstiv', 'git status --ignored --untracked-files --short ".%" | rg_grep -i -v "node_modules|\\.venv/|\\.rag/|__pycache__|DS_Store|\\.pytest_cache/|/bin/|/obj/|/target/|iterm2env/|egg-info/|dist/"', cursor_marker="%")  # Fish line 47
    abbr('gstiv_all', 'git status --ignored --untracked-files --short ".%" | rg_grep -i -v "node_modules|\\.venv/|\\.rag/|__pycache__|DS_Store|\\.pytest_cache/|/bin/|/obj/|/target/|iterm2env/|egg-info/|dist/|.*\\.(png|bmp|jpg|svg)\\$"', cursor_marker="%")  # Fish line 49
    abbr('grhh', 'git reset --hard HEAD')  # Fish line 52
    abbr('grh_undo_amend_commit', 'git reset --hard HEAD@{1}')  # Fish line 54
    abbr('grsh', 'git reset --soft HEAD~1')  # Fish line 57
    abbr('groh', 'git reset --hard ORIG_HEAD')  # Fish line 58
    abbr('gclean', 'git clean -d --dry-run')  # Fish line 62
    abbr('gcleani', 'git clean -d --interactive')  # Fish line 63
    abbr('gcleanx', 'git clean -d -x --dry-run')  # Fish line 64
    abbr('gpristine', 'git reset --hard && git clean -dffx')  # Fish line 65
    abbr('ga', 'git add')  # Fish line 68
    abbr('ga.', 'git add .')  # Fish line 69
    abbr('ga..', 'git add ..')  # Fish line 70
    abbr('gav', 'git add --verbose')  # Fish line 71
    abbr('gaa', 'git add --all')  # Fish line 72
    abbr('gaaa', 'git add --all')  # Fish line 73
    abbr('gau', 'git add --update')  # Fish line 74
    abbr('gap', 'git add --patch')  # Fish line 75
    abbr('gai', 'git add --interactive')  # Fish line 76
    abbr('gb', 'git branch')  # Fish line 80
    abbr('gbv', 'PAGER= git branch -vv')  # Fish line 81
    abbr('gba', 'PAGER= git branch --all -vv')  # Fish line 82
    abbr('gbr', 'PAGER= git branch --remotes -vv')  # Fish line 83
    abbr('gbd', 'git branch --delete')  # Fish line 85
    abbr('gbD', 'git branch -D')  # Fish line 86
    abbr('gbdf', 'git branch --delete --force')  # Fish line 87
    abbr('gbl', 'git blame -b -w')  # Fish line 97
    abbr('review', "git commit -a -m 'review'")  # Fish line 100
    abbr('notes', "git commit -a -m 'notes'")  # Fish line 101
    abbr('gc', 'GIT_EDITOR=git-commit-with-function-context git commit')  # Fish line 106
    abbr('gca', 'GIT_EDITOR=git-commit-with-function-context git commit -a')  # Fish line 107
    abbr('gc!', 'GIT_EDITOR=git-commit-with-function-context git commit --amend')  # Fish line 109
    abbr('gcn!', 'git commit --no-edit --amend')  # Fish line 110
    abbr('gca!', 'GIT_EDITOR=git-commit-with-function-context git commit -a --amend')  # Fish line 111
    abbr('gcan!', 'git commit -a --no-edit --amend')  # Fish line 112
    abbr('gco', 'git checkout')  # Fish line 115
    abbr('gcom', 'git checkout master')  # Fish line 116
    abbr('gcop', 'git restore --patch')  # Fish line 117
    abbr('gcob', 'git checkout -b')  # Fish line 118
    abbr('gconf', 'grc git config --list --show-origin --show-scope')  # Fish line 121
    abbr('gnoconf', 'env GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null grc git config --list --show-origin --show-scope')  # Fish line 122
    abbr('gnoconf_export', 'export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null')  # Fish line 123
    abbr('gcl', 'git clone --recurse-submodules')  # Fish line 127
    abbr('gcl_no_lfs', 'GIT_LFS_SKIP_SMUDGE=1 git clone --recurse-submodules')  # Fish line 128
    abbr('wcl_no_lfs', 'GIT_LFS_SKIP_SMUDGE=1 wcl')  # Fish line 129
    abbr('gf', 'git fetch')  # Fish line 137
    abbr('gfa', 'git fetch --all --prune --jobs=10')  # Fish line 138
    abbr('gp', 'git push')  # Fish line 141
    abbr('gpsup', 'git push --set-upstream origin $(git_current_branch)')  # Fish line 142
    abbr('gpd', 'git push --dry-run')  # Fish line 144
    abbr('gpf', 'git push --force')  # Fish line 145
    abbr('gpl', 'git pull')  # Fish line 149
    abbr('gplas', 'git pull --autostash')  # Fish line 150
    abbr('gplr', 'git pull --recurse-submodules')  # Fish line 151
    abbr('gr', 'git remote')  # Fish line 155
    abbr('grv', 'git remote -v')  # Fish line 156
    abbr('gra', 'git remote add')  # Fish line 157
    abbr('grao', 'git remote add origin')  # Fish line 158
    abbr('grau', 'git remote add upstream')  # Fish line 159
    abbr('grsuo', 'git remote set-url origin')  # Fish line 160
    abbr('grsuu', 'git remote set-url upstream')  # Fish line 161
    abbr('grup', 'git remote update')  # Fish line 162
    abbr('gm', 'git merge')  # Fish line 165
    abbr('gma', 'git merge --abort')  # Fish line 166
    abbr('gmc', 'git merge --continue')  # Fish line 167
    abbr('gmff', 'git merge --ff-only')  # Fish line 168
    abbr(re.compile('grev\\d+'), _fish_abbreviation('_abbr_expand_grev_d'))  # Fish line 171
    abbr('grm', 'git rm')  # Fish line 177
    abbr('grmc', 'git rm --cached')  # Fish line 178
    abbr('grst', 'git restore --staged')  # Fish line 181
    abbr('grstp', 'git restore --staged --patch')  # Fish line 182
    abbr('grstr', 'git restore --staged $(_repo_root)')  # Fish line 183
    abbr('grp', 'git restore --patch')  # Fish line 186
    abbr('grss', 'git restore --source')  # Fish line 187
    abbr('grevp_upstream', 'git rev-parse @{upstream}')  # Fish line 194
    abbr('grevp_upstream_symbolic', 'git rev-parse --symbolic-full-name @{upstream}')  # Fish line 195
    abbr('grevp_push', 'git rev-parse @{push}')  # Fish line 196
    abbr('grevp_push_symbolic', 'git rev-parse --symbolic-full-name @{push}')  # Fish line 197
    abbr('gsh', 'git show')  # Fish line 200
    abbr('gsh_file', 'git --no-pager show HEAD:%', cursor_marker="%")  # Fish line 201
    abbr('gsps', 'git show --pretty=short --show-signature')  # Fish line 202
    abbr('gcat', 'git cat-file -p HEAD:%', cursor_marker="%")  # Fish line 207
    abbr('gsm', 'git submodule')  # Fish line 213
    abbr('gsma', 'git submodule add --branch master')  # Fish line 214
    abbr('gsmd', 'git submodule deinit')  # Fish line 215
    abbr('gsmf', 'git submodule foreach')  # Fish line 216
    abbr('gsmfgl', 'git submodule foreach --recursive git pull')  # Fish line 217
    abbr('gsme', 'git submodule foreach')  # Fish line 218
    abbr('gsmi', 'git submodule init')  # Fish line 219
    abbr('gsmu', 'git submodule update --remote --recursive')  # Fish line 220
    abbr('gsmst', 'git submodule status --recursive')  # Fish line 221
    abbr('gsw', 'git switch')  # Fish line 224
    abbr('gswc', 'git switch -c')  # Fish line 225
    abbr('gts', 'git tag -s')  # Fish line 228
    abbr('gtv', 'git tag | sort -V')  # Fish line 229
    abbr('gassume', 'git update-index --assume-unchanged')  # Fish line 232
    abbr('gassumeun', 'git update-index --no-assume-unchanged')  # Fish line 233
    abbr('gassumels', 'git ls-files -v | rg_grep ^h')  # Fish line 234
    abbr('gd', 'git diff')  # Fish line 240
    abbr('gdu', 'git -c delta.side-by-side=false diff')  # Fish line 241
    abbr(re.compile('gd[u]*\\d+'), _fish_abbreviation('gdX'))  # Fish line 242
    abbr('gd_summary', 'git diff --summary')  # Fish line 256
    abbr('gd_worktree', 'git diff')  # Fish line 257
    abbr('gds', 'git diff --staged')  # Fish line 259
    abbr('gds_summary', 'git diff --staged --summary')  # Fish line 260
    abbr('gd_index', 'git diff --staged')  # Fish line 261
    abbr('git_diff_two_files', 'git diff --no-index')  # Fish line 263
    abbr('gdni', 'git diff --no-index')  # Fish line 264
    abbr('git_diff_two_dirs', "git diff --no-index __dir1__ __dir2__ '*foo*'")  # Fish line 265
    abbr('gd_is_worktree_clean', 'git diff --quiet')  # Fish line 267
    abbr('gd_is_index_clean', 'git diff --staged --quiet')  # Fish line 268
    abbr('gdlf', 'git diff-tree -r HEAD~1 HEAD')  # Fish line 270
    abbr('dsf', 'diff-so-fancy')  # Fish line 272
    abbr('lfs', 'git lfs')  # Fish line 276
    abbr('lfsi', 'git lfs install')  # Fish line 277
    abbr('lfsls', 'git lfs ls-files')  # Fish line 278
    abbr('lfsm', 'git lfs migrate')  # Fish line 279
    abbr('lfspr', 'git lfs prune')  # Fish line 280
    abbr('lfsst', 'git lfs status')  # Fish line 281
    abbr('lfst', "git lfs track '*.EXT'")  # Fish line 282
    abbr('lfsup', 'git lfs update')  # Fish line 283
    abbr('lfsut', "git lfs untrack '*.EXT'")  # Fish line 284
    abbr('lfsv', 'git lfs version')  # Fish line 285
    abbr('grvcp', _fish_abbreviation('_grvcp'))  # Fish line 288
    abbr('gcmsg', 'git commit -m "%"', cursor_marker="%")  # Fish line 314
    abbr('gcam', 'git commit -a -m "%"', cursor_marker="%")  # Fish line 315
    abbr('gptoss', '--author "gptoss120b<wes.mcclure+gptoss120b@gmail.com>"', commands=('git',))  # Fish line 318
    abbr('qwen3', '--author "qwen3.6-35b-a3b<wes.mcclure+qwen3.6-35b-a3b@gmail.com>"', commands=('git',))  # Fish line 319
    abbr('agentworld', '--author "qwen-agentworld-35b-a3b<wes.mcclure+qwen-agentworld-35b-a3b@gmail.com>"', commands=('git',))  # Fish line 320
    abbr('codex', '--author "codex-gpt5<wes.mcclure+codex-gpt5@gmail.com>"', commands=('git',))  # Fish line 321
    abbr('deepseek', '--author "deepseek-v4-flash-0731<wes.mcclure+deepseek-v4-flash-0731@gmail.com>"', commands=('git',))  # Fish line 322
    abbr('muse', '--author "muse-glimmer-30b-dspark<wes.mcclure+muse-glimmer-30b-dspark@gmail.com>"', commands=('git',))  # Fish line 323
    abbr('amend_n_gptoss', 'GIT_SEQUENCE_EDITOR=true git rebase -i --exec "git commit --amend --no-edit --author \\"gptoss120b<wes.mcclure+gptoss120b@gmail.com>\\"" HEAD~%', cursor_marker="%")  # Fish line 327
    abbr('amend_n_qwen3', 'GIT_SEQUENCE_EDITOR=true git rebase -i --exec "git commit --amend --no-edit --author \\"qwen3.6-35b-a3b<wes.mcclure+qwen3.6-35b-a3b@gmail.com>\\"" HEAD~%', cursor_marker="%")  # Fish line 328
    abbr('amend_n_agentworld', 'GIT_SEQUENCE_EDITOR=true git rebase -i --exec "git commit --amend --no-edit --author \\"qwen-agentworld-35b-a3b<wes.mcclure+qwen-agentworld-35b-a3b@gmail.com>\\"" HEAD~%', cursor_marker="%")  # Fish line 329
    abbr('amend_n_codex', 'GIT_SEQUENCE_EDITOR=true git rebase -i --exec "git commit --amend --no-edit --author \\"codex-gpt5<wes.mcclure+codex-gpt5@gmail.com>\\"" HEAD~%', cursor_marker="%")  # Fish line 330
    abbr('amend_n_deepseek', 'GIT_SEQUENCE_EDITOR=true git rebase -i --exec "git commit --amend --no-edit --author \\"deepseek-v4-flash-0731<wes.mcclure+deepseek-v4-flash-0731@gmail.com>\\"" HEAD~%', cursor_marker="%")  # Fish line 331
    abbr('amend_n_muse', 'GIT_SEQUENCE_EDITOR=true git rebase -i --exec "git commit --amend --no-edit --author \\"muse-glimmer-30b-dspark<wes.mcclure+muse-glimmer-30b-dspark@gmail.com>\\"" HEAD~%', cursor_marker="%")  # Fish line 332
    abbr('amend_last_msg', 'git commit --amend -m "%"', cursor_marker="%")  # Fish line 336
    abbr('yolo', 'git commit --all -m "%" && git push', cursor_marker="%")  # Fish line 339
    abbr(re.compile('gptf?\\d*f?'), _fish_abbreviation('_abbr_git_push_up_to'), cursor_marker="%")  # Fish line 343
    abbr('grl', 'git reflog --pretty=reflog')  # Fish line 363
    abbr('grla', 'git reflog --all --pretty=reflog')  # Fish line 364
    abbr('gl', 'git log --color=always | line_numbers')  # Fish line 366
    abbr('glemails', 'git log --pretty=names')  # Fish line 367
    abbr('glnames', 'git log --pretty=names')  # Fish line 368
    abbr(re.compile('gl\\d+'), _fish_abbreviation('glX'))  # Fish line 371
    abbr(re.compile('g\\d+'), _fish_abbreviation('glX'))  # Fish line 372
    abbr('gst', 'git status')  # Fish line 384
    abbr('gstl', 'git status && echo && git_unpushed_commits')  # Fish line 386
    abbr('glo', 'git_unpushed_commits')  # Fish line 414
    abbr('gup', 'git_unpushed_commits')  # Fish line 415
    abbr('gout', 'git_unpushed_commits')  # Fish line 432
    abbr('gin', 'git_unpulled_commits')  # Fish line 433
    abbr('glp', 'git log --patch')  # Fish line 448
    abbr('glpf', 'git log --pretty=full --patch')  # Fish line 449
    abbr(re.compile('glpf?\\d+'), _fish_abbreviation('glp_x'))  # Fish line 450
    abbr('gls', "git log --stat 'HEAD@{push}..HEAD'")  # Fish line 462
    abbr('glsf', "git log --pretty=full --stat 'HEAD@{push}..HEAD'")  # Fish line 463
    abbr(re.compile('gls[f]{0,1}\\d+'), _fish_abbreviation('glsX'))  # Fish line 464
    abbr('glg', "git log --graph 'HEAD@{push}~1..HEAD'")  # Fish line 473
    abbr('ggsup', 'git branch --set-upstream-to=origin/$(git_current_branch)')  # Fish line 485
    abbr('git_delta_copyable', 'git -c delta.side-by-side=false -c delta.line-numbers=false')  # Fish line 492
    abbr('git_delta_side_by_side', 'git -c delta.side-by-side=true')  # Fish line 493
    abbr('git_delta_unified', 'git -c delta.side-by-side=false')  # Fish line 494
    abbr('git_delta_no_line_numbers', 'git -c delta.line-numbers=false')  # Fish line 495
    abbr('git_ignore_space_changes', 'git diff --ignore-space-change')  # Fish line 514
    abbr('git_ignore_all_space', 'git diff --ignore-all-space')  # Fish line 515
    abbr('gdlc', 'git log --patch HEAD~1..HEAD')  # Fish line 517
    abbr('gdlcu', 'git -c delta.side-by-side=false log --patch HEAD~1..HEAD')  # Fish line 518
    abbr(re.compile('gdlc[u]?\\d+'), _fish_abbreviation('gdlcX'))  # Fish line 519
    abbr('gd_stat', "git diff --stat 'HEAD@{push}..HEAD'")  # Fish line 533
    abbr('glgrep', 'git log --grep="%"', cursor_marker="%")  # Fish line 542
    abbr('gd_patch', 'git --no-pager diff --no-color')  # Fish line 545
    abbr('rr', '_repo_root')  # Fish line 598
    abbr('gwt', 'git worktree')  # Fish line 619
    abbr('gwtls', 'git worktree list')  # Fish line 620
    abbr('gwta', 'git worktree add')  # Fish line 621
    abbr('gwtab', 'git worktree add -b')  # Fish line 622
    abbr('gwtrm', 'git worktree remove')  # Fish line 623
    abbr('gwtm', 'git worktree move')  # Fish line 624
    abbr('grb', 'git rebase')  # Fish line 628
    abbr('grba', 'git rebase --abort')  # Fish line 629
    abbr('grbc', 'git rebase --continue')  # Fish line 630
    abbr('grbs', 'git rebase --skip')  # Fish line 631
    abbr('grbi', 'git rebase -i')  # Fish line 632
    abbr('grbias', 'git rebase -i --autostash')  # Fish line 633
    abbr(re.compile('grbi\\d+'), _fish_abbreviation('_abbr_expand_grbi_d'))  # Fish line 635
    abbr('gstash', 'git stash')  # Fish line 657
    abbr('git_stash_list', 'git stash list --pretty=stash-list')  # Fish line 658
    abbr('git_stash_show', 'git stash show --text 0')  # Fish line 660
    abbr('git_stash_drop', 'git stash drop 0')  # Fish line 663
    abbr('git_stash_pop', 'git stash pop 0')  # Fish line 664
    abbr('git_stash_apply', 'git stash apply')  # Fish line 665
    abbr('git_stash_branch', 'git stash branch')  # Fish line 666
    abbr('git_stash_patch', 'git stash push --patch --no-keep-index')  # Fish line 667
    abbr(re.compile('gap\\d*'), _fish_abbreviation('gapX'))  # Fish line 671
    abbr('git_stash_push', 'git stash push --message "%"', cursor_marker="%")  # Fish line 682
    abbr('git_stash_save', 'git stash push --message "%"', cursor_marker="%")  # Fish line 683
    abbr('git_stash_clear', 'git stash clear')  # Fish line 684
    abbr('git_archive_tgz', 'git archive --format=tgz --output repo.tgz HEAD')  # Fish line 715
    abbr('git_archive_zip', 'git archive --format=zip --output repo.zip HEAD')  # Fish line 716
    abbr('git_archive_everything', 'git bundle create repo.bundle --all')  # Fish line 717
    abbr('gg', "git grep -Ee '%' $(git rev-list --all)", cursor_marker="%")  # Fish line 722
    abbr('ggc', "git grep -C10 -Ee '%' $(git rev-list --all)", cursor_marker="%")  # Fish line 723
    abbr('ggf', "git grep --function-context -Ee '%' $(git rev-list --all)", cursor_marker="%")  # Fish line 724
