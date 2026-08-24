"""Git abbreviations generated from fish/load_last_interactive_only/git.fish."""

from __future__ import annotations

import re

from wes_abbreviations import AbbreviationRegistry, abbr
from wes_fish_bridge import fish_function


def _fish_abbreviation(function_name):
    def expand(context, _match):
        return fish_function(function_name, context.token)

    return expand


def register_git_abbreviations(registry: AbbreviationRegistry):
    abbr(registry, "-W", "--function-context", commands=("git", "diff"))
    abbr(registry, 'man_gitrevisions', 'man gitrevisions')  # Fish line 25
    abbr(registry, re.compile('reflog\\d+'), _fish_abbreviation('_abbr_expand_reflog_d'), position="anywhere")  # Fish line 30
    abbr(registry, 'commit_with_message', ':/%', position="anywhere", cursor_marker="%")  # Fish line 35
    abbr(registry, 'gsts', 'git status -s')  # Fish line 39
    abbr(registry, 'gstb', 'git status -sb')  # Fish line 40
    abbr(registry, 'gstu', 'git status --untracked-files')  # Fish line 41
    abbr(registry, 'gsti', 'git status --ignored .')  # Fish line 43
    abbr(registry, 'gstiv', 'git status --ignored --untracked-files --short ".%" | rg_grep -i -v "node_modules|\\.venv/|\\.rag/|__pycache__|DS_Store|\\.pytest_cache/|/bin/|/obj/|/target/|iterm2env/|egg-info/|dist/"', cursor_marker="%")  # Fish line 47
    abbr(registry, 'gstiv_all', 'git status --ignored --untracked-files --short ".%" | rg_grep -i -v "node_modules|\\.venv/|\\.rag/|__pycache__|DS_Store|\\.pytest_cache/|/bin/|/obj/|/target/|iterm2env/|egg-info/|dist/|.*\\.(png|bmp|jpg|svg)\\$"', cursor_marker="%")  # Fish line 49
    abbr(registry, 'grhh', 'git reset --hard HEAD')  # Fish line 52
    abbr(registry, 'grh_undo_amend_commit', 'git reset --hard HEAD@{1}')  # Fish line 54
    abbr(registry, 'grsh', 'git reset --soft HEAD~1')  # Fish line 57
    abbr(registry, 'groh', 'git reset --hard ORIG_HEAD')  # Fish line 58
    abbr(registry, 'gclean', 'git clean -d --dry-run')  # Fish line 62
    abbr(registry, 'gcleani', 'git clean -d --interactive')  # Fish line 63
    abbr(registry, 'gcleanx', 'git clean -d -x --dry-run')  # Fish line 64
    abbr(registry, 'gpristine', 'git reset --hard && git clean -dffx')  # Fish line 65
    abbr(registry, 'ga', 'git add')  # Fish line 68
    abbr(registry, 'ga.', 'git add .')  # Fish line 69
    abbr(registry, 'ga..', 'git add ..')  # Fish line 70
    abbr(registry, 'gav', 'git add --verbose')  # Fish line 71
    abbr(registry, 'gaa', 'git add --all')  # Fish line 72
    abbr(registry, 'gaaa', 'git add --all')  # Fish line 73
    abbr(registry, 'gau', 'git add --update')  # Fish line 74
    abbr(registry, 'gap', 'git add --patch')  # Fish line 75
    abbr(registry, 'gai', 'git add --interactive')  # Fish line 76
    abbr(registry, 'gb', 'git branch')  # Fish line 80
    abbr(registry, 'gbv', 'PAGER= git branch -vv')  # Fish line 81
    abbr(registry, 'gba', 'PAGER= git branch --all -vv')  # Fish line 82
    abbr(registry, 'gbr', 'PAGER= git branch --remotes -vv')  # Fish line 83
    abbr(registry, 'gbd', 'git branch --delete')  # Fish line 85
    abbr(registry, 'gbD', 'git branch -D')  # Fish line 86
    abbr(registry, 'gbdf', 'git branch --delete --force')  # Fish line 87
    abbr(registry, 'gbl', 'git blame -b -w')  # Fish line 97
    abbr(registry, 'review', "git commit -a -m 'review'")  # Fish line 100
    abbr(registry, 'notes', "git commit -a -m 'notes'")  # Fish line 101
    abbr(registry, 'gc', 'GIT_EDITOR=git-commit-with-function-context git commit')  # Fish line 106
    abbr(registry, 'gca', 'GIT_EDITOR=git-commit-with-function-context git commit -a')  # Fish line 107
    abbr(registry, 'gc!', 'GIT_EDITOR=git-commit-with-function-context git commit --amend')  # Fish line 109
    abbr(registry, 'gcn!', 'git commit --no-edit --amend')  # Fish line 110
    abbr(registry, 'gca!', 'GIT_EDITOR=git-commit-with-function-context git commit -a --amend')  # Fish line 111
    abbr(registry, 'gcan!', 'git commit -a --no-edit --amend')  # Fish line 112
    abbr(registry, 'gco', 'git checkout')  # Fish line 115
    abbr(registry, 'gcom', 'git checkout master')  # Fish line 116
    abbr(registry, 'gcop', 'git restore --patch')  # Fish line 117
    abbr(registry, 'gcob', 'git checkout -b')  # Fish line 118
    abbr(registry, 'gconf', 'grc git config --list --show-origin --show-scope')  # Fish line 121
    abbr(registry, 'gnoconf', 'env GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null grc git config --list --show-origin --show-scope')  # Fish line 122
    abbr(registry, 'gnoconf_export', 'export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null')  # Fish line 123
    abbr(registry, 'gcl', 'git clone --recurse-submodules')  # Fish line 127
    abbr(registry, 'gcl_no_lfs', 'GIT_LFS_SKIP_SMUDGE=1 git clone --recurse-submodules')  # Fish line 128
    abbr(registry, 'wcl_no_lfs', 'GIT_LFS_SKIP_SMUDGE=1 wcl')  # Fish line 129
    abbr(registry, 'gf', 'git fetch')  # Fish line 137
    abbr(registry, 'gfa', 'git fetch --all --prune --jobs=10')  # Fish line 138
    abbr(registry, 'gp', 'git push')  # Fish line 141
    abbr(registry, 'gpsup', 'git push --set-upstream origin $(git_current_branch)')  # Fish line 142
    abbr(registry, 'gpd', 'git push --dry-run')  # Fish line 144
    abbr(registry, 'gpf', 'git push --force')  # Fish line 145
    abbr(registry, 'gpl', 'git pull')  # Fish line 149
    abbr(registry, 'gplas', 'git pull --autostash')  # Fish line 150
    abbr(registry, 'gplr', 'git pull --recurse-submodules')  # Fish line 151
    abbr(registry, 'gr', 'git remote')  # Fish line 155
    abbr(registry, 'grv', 'git remote -v')  # Fish line 156
    abbr(registry, 'gra', 'git remote add')  # Fish line 157
    abbr(registry, 'grao', 'git remote add origin')  # Fish line 158
    abbr(registry, 'grau', 'git remote add upstream')  # Fish line 159
    abbr(registry, 'grsuo', 'git remote set-url origin')  # Fish line 160
    abbr(registry, 'grsuu', 'git remote set-url upstream')  # Fish line 161
    abbr(registry, 'grup', 'git remote update')  # Fish line 162
    abbr(registry, 'gm', 'git merge')  # Fish line 165
    abbr(registry, 'gma', 'git merge --abort')  # Fish line 166
    abbr(registry, 'gmc', 'git merge --continue')  # Fish line 167
    abbr(registry, 'gmff', 'git merge --ff-only')  # Fish line 168
    abbr(registry, re.compile('grev\\d+'), _fish_abbreviation('_abbr_expand_grev_d'))  # Fish line 171
    abbr(registry, 'grm', 'git rm')  # Fish line 177
    abbr(registry, 'grmc', 'git rm --cached')  # Fish line 178
    abbr(registry, 'grst', 'git restore --staged')  # Fish line 181
    abbr(registry, 'grstp', 'git restore --staged --patch')  # Fish line 182
    abbr(registry, 'grstr', 'git restore --staged "$(_repo_root)"')  # Fish line 183
    abbr(registry, 'grp', 'git restore --patch')  # Fish line 186
    abbr(registry, 'grss', 'git restore --source')  # Fish line 187
    abbr(registry, 'grevp_upstream', 'git rev-parse @{upstream}')  # Fish line 194
    abbr(registry, 'grevp_upstream_symbolic', 'git rev-parse --symbolic-full-name @{upstream}')  # Fish line 195
    abbr(registry, 'grevp_push', 'git rev-parse @{push}')  # Fish line 196
    abbr(registry, 'grevp_push_symbolic', 'git rev-parse --symbolic-full-name @{push}')  # Fish line 197
    abbr(registry, 'gsh', 'git show')  # Fish line 200
    abbr(registry, 'gsh_file', 'git --no-pager show HEAD:%', cursor_marker="%")  # Fish line 201
    abbr(registry, 'gsps', 'git show --pretty=short --show-signature')  # Fish line 202
    abbr(registry, 'gcat', 'git cat-file -p HEAD:%', cursor_marker="%")  # Fish line 207
    abbr(registry, 'gsm', 'git submodule')  # Fish line 213
    abbr(registry, 'gsma', 'git submodule add --branch master')  # Fish line 214
    abbr(registry, 'gsmd', 'git submodule deinit')  # Fish line 215
    abbr(registry, 'gsmf', 'git submodule foreach')  # Fish line 216
    abbr(registry, 'gsmfgl', 'git submodule foreach --recursive git pull')  # Fish line 217
    abbr(registry, 'gsme', 'git submodule foreach')  # Fish line 218
    abbr(registry, 'gsmi', 'git submodule init')  # Fish line 219
    abbr(registry, 'gsmu', 'git submodule update --remote --recursive')  # Fish line 220
    abbr(registry, 'gsmst', 'git submodule status --recursive')  # Fish line 221
    abbr(registry, 'gsw', 'git switch')  # Fish line 224
    abbr(registry, 'gswc', 'git switch -c')  # Fish line 225
    abbr(registry, 'gts', 'git tag -s')  # Fish line 228
    abbr(registry, 'gtv', 'git tag | sort -V')  # Fish line 229
    abbr(registry, 'gassume', 'git update-index --assume-unchanged')  # Fish line 232
    abbr(registry, 'gassumeun', 'git update-index --no-assume-unchanged')  # Fish line 233
    abbr(registry, 'gassumels', 'git ls-files -v | rg_grep ^h')  # Fish line 234
    abbr(registry, 'gd', 'git diff')  # Fish line 240
    abbr(registry, 'gdu', 'git -c delta.side-by-side=false diff')  # Fish line 241
    abbr(registry, re.compile('gd[u]*\\d+'), _fish_abbreviation('gdX'))  # Fish line 242
    abbr(registry, 'gd_summary', 'git diff --summary')  # Fish line 256
    abbr(registry, 'gd_worktree', 'git diff')  # Fish line 257
    abbr(registry, 'gds', 'git diff --staged')  # Fish line 259
    abbr(registry, 'gds_summary', 'git diff --staged --summary')  # Fish line 260
    abbr(registry, 'gd_index', 'git diff --staged')  # Fish line 261
    abbr(registry, 'git_diff_two_files', 'git diff --no-index')  # Fish line 263
    abbr(registry, 'gdni', 'git diff --no-index')  # Fish line 264
    abbr(registry, 'git_diff_two_dirs', "git diff --no-index __dir1__ __dir2__ '*foo*'")  # Fish line 265
    abbr(registry, 'gd_is_worktree_clean', 'git diff --quiet')  # Fish line 267
    abbr(registry, 'gd_is_index_clean', 'git diff --staged --quiet')  # Fish line 268
    abbr(registry, 'gdlf', 'git diff-tree -r HEAD~1 HEAD')  # Fish line 270
    abbr(registry, 'dsf', 'diff-so-fancy')  # Fish line 272
    abbr(registry, 'lfs', 'git lfs')  # Fish line 276
    abbr(registry, 'lfsi', 'git lfs install')  # Fish line 277
    abbr(registry, 'lfsls', 'git lfs ls-files')  # Fish line 278
    abbr(registry, 'lfsm', 'git lfs migrate')  # Fish line 279
    abbr(registry, 'lfspr', 'git lfs prune')  # Fish line 280
    abbr(registry, 'lfsst', 'git lfs status')  # Fish line 281
    abbr(registry, 'lfst', "git lfs track '*.EXT'")  # Fish line 282
    abbr(registry, 'lfsup', 'git lfs update')  # Fish line 283
    abbr(registry, 'lfsut', "git lfs untrack '*.EXT'")  # Fish line 284
    abbr(registry, 'lfsv', 'git lfs version')  # Fish line 285
    abbr(registry, 'grvcp', _fish_abbreviation('_grvcp'))  # Fish line 288
    abbr(registry, 'gcmsg', 'git commit -m "%"', cursor_marker="%")  # Fish line 314
    abbr(registry, 'gcam', 'git commit -a -m "%"', cursor_marker="%")  # Fish line 315
    abbr(registry, 'gptoss', '--author "gptoss120b<wes.mcclure+gptoss120b@gmail.com>"', commands=('git',))  # Fish line 318
    abbr(registry, 'qwen3', '--author "qwen3.6-35b-a3b<wes.mcclure+qwen3.6-35b-a3b@gmail.com>"', commands=('git',))  # Fish line 319
    abbr(registry, 'agentworld', '--author "qwen-agentworld-35b-a3b<wes.mcclure+qwen-agentworld-35b-a3b@gmail.com>"', commands=('git',))  # Fish line 320
    abbr(registry, 'codex', '--author "codex-gpt5<wes.mcclure+codex-gpt5@gmail.com>"', commands=('git',))  # Fish line 321
    abbr(registry, 'deepseek', '--author "deepseek-v4-flash-0731<wes.mcclure+deepseek-v4-flash-0731@gmail.com>"', commands=('git',))  # Fish line 322
    abbr(registry, 'muse', '--author "muse-glimmer-30b-dspark<wes.mcclure+muse-glimmer-30b-dspark@gmail.com>"', commands=('git',))  # Fish line 323
    abbr(registry, 'amend_n_gptoss', 'GIT_SEQUENCE_EDITOR=true git rebase -i --exec "git commit --amend --no-edit --author \\"gptoss120b<wes.mcclure+gptoss120b@gmail.com>\\"" HEAD~%', cursor_marker="%")  # Fish line 327
    abbr(registry, 'amend_n_qwen3', 'GIT_SEQUENCE_EDITOR=true git rebase -i --exec "git commit --amend --no-edit --author \\"qwen3.6-35b-a3b<wes.mcclure+qwen3.6-35b-a3b@gmail.com>\\"" HEAD~%', cursor_marker="%")  # Fish line 328
    abbr(registry, 'amend_n_agentworld', 'GIT_SEQUENCE_EDITOR=true git rebase -i --exec "git commit --amend --no-edit --author \\"qwen-agentworld-35b-a3b<wes.mcclure+qwen-agentworld-35b-a3b@gmail.com>\\"" HEAD~%', cursor_marker="%")  # Fish line 329
    abbr(registry, 'amend_n_codex', 'GIT_SEQUENCE_EDITOR=true git rebase -i --exec "git commit --amend --no-edit --author \\"codex-gpt5<wes.mcclure+codex-gpt5@gmail.com>\\"" HEAD~%', cursor_marker="%")  # Fish line 330
    abbr(registry, 'amend_n_deepseek', 'GIT_SEQUENCE_EDITOR=true git rebase -i --exec "git commit --amend --no-edit --author \\"deepseek-v4-flash-0731<wes.mcclure+deepseek-v4-flash-0731@gmail.com>\\"" HEAD~%', cursor_marker="%")  # Fish line 331
    abbr(registry, 'amend_n_muse', 'GIT_SEQUENCE_EDITOR=true git rebase -i --exec "git commit --amend --no-edit --author \\"muse-glimmer-30b-dspark<wes.mcclure+muse-glimmer-30b-dspark@gmail.com>\\"" HEAD~%', cursor_marker="%")  # Fish line 332
    abbr(registry, 'amend_last_msg', 'git commit --amend -m "%"', cursor_marker="%")  # Fish line 336
    abbr(registry, 'yolo', 'git commit --all -m "%" && git push', cursor_marker="%")  # Fish line 339
    abbr(registry, re.compile('gptf?\\d*f?'), _fish_abbreviation('_abbr_git_push_up_to'), cursor_marker="%")  # Fish line 343
    abbr(registry, 'grl', 'git reflog --pretty=reflog')  # Fish line 363
    abbr(registry, 'grla', 'git reflog --all --pretty=reflog')  # Fish line 364
    abbr(registry, 'gl', 'git log --color=always | line_numbers')  # Fish line 366
    abbr(registry, 'glemails', 'git log --pretty=names')  # Fish line 367
    abbr(registry, 'glnames', 'git log --pretty=names')  # Fish line 368
    abbr(registry, re.compile('gl\\d+'), _fish_abbreviation('glX'))  # Fish line 371
    abbr(registry, re.compile('g\\d+'), _fish_abbreviation('glX'))  # Fish line 372
    abbr(registry, 'gst', 'git status')  # Fish line 384
    abbr(registry, 'gstl', 'git status && echo && git_unpushed_commits')  # Fish line 386
    abbr(registry, 'glo', 'git_unpushed_commits')  # Fish line 414
    abbr(registry, 'gup', 'git_unpushed_commits')  # Fish line 415
    abbr(registry, 'gout', 'git_unpushed_commits')  # Fish line 432
    abbr(registry, 'gin', 'git_unpulled_commits')  # Fish line 433
    abbr(registry, 'glp', 'git log --patch')  # Fish line 448
    abbr(registry, 'glpf', 'git log --pretty=full --patch')  # Fish line 449
    abbr(registry, re.compile('glpf?\\d+'), _fish_abbreviation('glp_x'))  # Fish line 450
    abbr(registry, 'gls', 'git log --stat HEAD@{push}..HEAD')  # Fish line 462
    abbr(registry, 'glsf', 'git log --pretty=full --stat HEAD@{push}..HEAD')  # Fish line 463
    abbr(registry, re.compile('gls[f]{0,1}\\d+'), _fish_abbreviation('glsX'))  # Fish line 464
    abbr(registry, 'glg', 'git log --graph HEAD@{push}~1..HEAD')  # Fish line 473
    abbr(registry, 'ggsup', 'git branch --set-upstream-to=origin/$(git_current_branch)')  # Fish line 485
    abbr(registry, 'git_delta_copyable', 'git -c delta.side-by-side=false -c delta.line-numbers=false')  # Fish line 492
    abbr(registry, 'git_delta_side_by_side', 'git -c delta.side-by-side=true')  # Fish line 493
    abbr(registry, 'git_delta_unified', 'git -c delta.side-by-side=false')  # Fish line 494
    abbr(registry, 'git_delta_no_line_numbers', 'git -c delta.line-numbers=false')  # Fish line 495
    abbr(registry, 'git_ignore_space_changes', 'git diff --ignore-space-change')  # Fish line 514
    abbr(registry, 'git_ignore_all_space', 'git diff --ignore-all-space')  # Fish line 515
    abbr(registry, 'gdlc', 'git log --patch HEAD~1..HEAD')  # Fish line 517
    abbr(registry, 'gdlcu', 'git -c delta.side-by-side=false log --patch HEAD~1..HEAD')  # Fish line 518
    abbr(registry, re.compile('gdlc[u]?\\d+'), _fish_abbreviation('gdlcX'))  # Fish line 519
    abbr(registry, 'gd_stat', 'git diff --stat HEAD@{push}..HEAD')  # Fish line 533
    abbr(registry, 'glgrep', 'git log --grep="%"', cursor_marker="%")  # Fish line 542
    abbr(registry, 'gd_patch', 'git --no-pager diff --no-color')  # Fish line 545
    abbr(registry, 'rr', '_repo_root')  # Fish line 598
    abbr(registry, 'gwt', 'git worktree')  # Fish line 619
    abbr(registry, 'gwtls', 'git worktree list')  # Fish line 620
    abbr(registry, 'gwta', 'git worktree add')  # Fish line 621
    abbr(registry, 'gwtab', 'git worktree add -b')  # Fish line 622
    abbr(registry, 'gwtrm', 'git worktree remove')  # Fish line 623
    abbr(registry, 'gwtm', 'git worktree move')  # Fish line 624
    abbr(registry, 'grb', 'git rebase')  # Fish line 628
    abbr(registry, 'grba', 'git rebase --abort')  # Fish line 629
    abbr(registry, 'grbc', 'git rebase --continue')  # Fish line 630
    abbr(registry, 'grbs', 'git rebase --skip')  # Fish line 631
    abbr(registry, 'grbi', 'git rebase -i')  # Fish line 632
    abbr(registry, 'grbias', 'git rebase -i --autostash')  # Fish line 633
    abbr(registry, re.compile('grbi\\d+'), _fish_abbreviation('_abbr_expand_grbi_d'))  # Fish line 635
    abbr(registry, 'gstash', 'git stash')  # Fish line 657
    abbr(registry, 'git_stash_list', 'git stash list --pretty=stash-list')  # Fish line 658
    abbr(registry, 'git_stash_show', 'git stash show --text 0')  # Fish line 660
    abbr(registry, 'git_stash_drop', 'git stash drop 0')  # Fish line 663
    abbr(registry, 'git_stash_pop', 'git stash pop 0')  # Fish line 664
    abbr(registry, 'git_stash_apply', 'git stash apply')  # Fish line 665
    abbr(registry, 'git_stash_branch', 'git stash branch')  # Fish line 666
    abbr(registry, 'git_stash_patch', 'git stash push --patch --no-keep-index')  # Fish line 667
    abbr(registry, re.compile('gap\\d*'), _fish_abbreviation('gapX'))  # Fish line 671
    abbr(registry, 'git_stash_push', 'git stash push --message "%"', cursor_marker="%")  # Fish line 682
    abbr(registry, 'git_stash_save', 'git stash push --message "%"', cursor_marker="%")  # Fish line 683
    abbr(registry, 'git_stash_clear', 'git stash clear')  # Fish line 684
    abbr(registry, 'git_archive_tgz', 'git archive --format=tgz --output repo.tgz HEAD')  # Fish line 715
    abbr(registry, 'git_archive_zip', 'git archive --format=zip --output repo.zip HEAD')  # Fish line 716
    abbr(registry, 'git_archive_everything', 'git bundle create repo.bundle --all')  # Fish line 717
    abbr(registry, 'gg', "git grep -Ee '%' $(git rev-list --all)", cursor_marker="%")  # Fish line 722
    abbr(registry, 'ggc', "git grep -C10 -Ee '%' $(git rev-list --all)", cursor_marker="%")  # Fish line 723
    abbr(registry, 'ggf', "git grep --function-context -Ee '%' $(git rev-list --all)", cursor_marker="%")  # Fish line 724
