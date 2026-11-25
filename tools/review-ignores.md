# Reviewing ignored files in a checkout

A fresh clone should be enough to recover the code. Sync should supply any durable files deliberately kept out of version control, on any machine or account. Keeping those files outside the checkout also keeps routine recursive searches from picking them up. A file can be fine to share and still lack the deliberate publication decision that a commit records.

1. Run `gstiv` for a first pass. Cross-check with `git ls-files --others --ignored --exclude-standard --directory --no-empty-directory` from the repo root. Inspect directories the summary collapses before classifying them. Keep the filter for reproducible dependencies and caches such as `.venv`, `node_modules`, and `.rag`. A generic directory name like `bin` can also contain hand-written tools.
2. Flag each repo-specific ignored item. Track inputs that belong in a clone, including application lockfiles. Propose moving durable unversioned inputs to Sync, put regenerable outputs in a user cache, and create scratch files in a per-run temporary directory. Check the generator as well as every reader.
3. For Sync inputs, build the path from `dropbox_sync_dir` and a relative suffix. Set the variable once per environment. In prose, “Sync” or `dropbox_sync_dir` is enough. Check known cross-repo consumers when applicable.
4. Run `tools/review_repo_symlinks.py /path/to/checkout` from dotfiles. It includes tracked, untracked, and ignored links, reports checkout-relative names, and exits 1 for findings. It skips Git metadata and common dependency/cache trees. Use `--all` to include those trees. The scan reads link destinations without walking linked directories.
5. Keep links whose resolved targets stay inside the checkout. For external links, update callers to construct the path from an environment variable, exercise the new lookup, then remove the link. Review an unresolvable link individually. A directory link into Sync makes it easy for a tool following links to traverse much more than intended.
6. Verify moved files arrived intact, rerun the inventory, and check that the old path is gone. Keep flagging new repo-specific entries until each has a deliberate home.

## Reviewing a trace for sharing

Leave the trace and its README uncommitted until the sharing review is complete. Check the output of commands that searched above a repo. Even a filename-only search can capture unrelated private directory names.

It's fine to withdraw a trace from public sharing at any point. Move the whole capture directory, including its README, under `$dropbox_sync_dir/ask-openai-research/private-traces-rug` and verify the private copy. If the files were staged, clear their index entries. If they were already committed locally, remove the trace from the unpublished commits while preserving unrelated work. Verify that no branch or tag intended for sharing still contains it. A later deletion commit leaves the original trace in history. If the trace was already pushed, flag that separately.
