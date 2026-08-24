"""Deferred Xonsh ideas that should remain searchable beside the active rc files."""


# Migration rule: Fish functions that must be rewritten instead of bridged.
#
# A `fish -ic function_name` bridge is preferred while it preserves behavior,
# but it runs in a child Fish process. Rewrite a function natively when it uses:
#   - `commandline`: it reads or edits Fish's reader buffer, not Xonsh's Prompt
#     Toolkit buffer. Use `event.current_buffer` in a Xonsh keybinding.
#   - `history` for current interactive state: the child has Fish history, not
#     the active Xonsh session. Use `XSH.history.inps` (or Prompt Toolkit history
#     when editor-specific ordering is intended).
#   - `cd`, exported/universal variables, aliases, abbr, bind, complete, source,
#     or event handlers for a persistent current-shell side effect: changes in
#     the child disappear when `fish -ic` exits.
#   - interactive/TTY job control, repainting, or an interactive selector whose
#     result edits the shell: stdin/stdout forwarding alone is insufficient.
#   - Fish syntax embedded in strings later passed to `eval`: Xonsh must parse
#     and execute the stored command instead.
#
# Pure computation and ordinary streamed commands remain good bridge candidates.
# Performance is the secondary test: measure startup overhead for hot paths, and
# port only when the bridge is observably costly.
#
# Process substitution (implemented in diff-specific.xsh / wes_diff.py):
#   Xonsh has captured subprocess forms but no built-in `<(...)` pathname syntax.
#   Our `$(producer | psub)` callable alias writes stdin to a tempfile and prints
#   its path; `events.on_postcommand` removes all substitutions after the outer
#   command finishes. `wes_diff.psub` also provides deterministic context-manager
#   lifetime for Python callable aliases that need multiple substitutions.


# TODO: Add Fish-style subsequence completion after learning stock Xonsh completion.
#
# Why this is deferred:
#   Keep native Xonsh completion, abbreviation expansion, and AI autosuggestions
#   distinguishable while learning how each behaves. This is not blocked on
#   feasibility; the implementation should be small and does not require a
#   Prompt Toolkit keybinding.
#
# Motivating example:
#   A Fish function named `what_shell` completes from `whatsh<Tab>`. The typed
#   characters are a case-sensitive subsequence of the candidate, so Fish
#   replaces the complete token with `what_shell`.
#
# Fish behavior worth preserving:
#   - Match ranks are exact/prefix, substring, then subsequence.
#   - Only candidates at the best available rank survive. Thus a prefix such as
#     `whatshovel` suppresses the weaker `what_shell` subsequence match.
#   - Subsequence matching is case-sensitive; Fish has no case-insensitive
#     subsequence fallback.
#   - One match replaces the entire token and normally appends a space.
#   - Multiple equally ranked matches open the completion pager.
#   - Explicit Tab completion is fuzzy; autosuggestion completion is not.
#   - In command position Fish considers PATH executables, functions, builtins,
#     implicit-cd directories, and non-regex abbreviations.
#
# Suggested first Xonsh scope:
#   - Register a contextual, non-exclusive, command-position-only completer.
#   - Start with Xonsh's command cache: aliases/functions and PATH executables.
#   - Yield full-token RichCompletion values with the typed token as prefix_len.
#   - Tag every result with provider="fish-fuzzy" so setting
#     `$XONSH_COMPLETER_TRACE = True` makes its origin unmistakable.
#   - Initially let native prefix/substring results coexist and sort first. Once
#     this has been used for a while, decide whether to copy Fish's stricter
#     best-rank-only filtering.
#   - Do nothing for arguments, quoted strings, or Python expression contexts.
#
# Tests to write first:
#   - `whatsh` matches `what_shell` and replaces the full token.
#   - Characters must occur in order; matching is case-sensitive.
#   - Exact, prefix, and substring matches rank ahead of subsequences.
#   - Multiple matches are stable and duplicates are removed.
#   - The completer applies only at command position, including after a pipe or
#     command separator, and does not leak into argument completion.
#   - Alias descriptions and alias/command provider information are retained.
#
# Research:
#   https://github.com/fish-shell/fish-shell/blob/master/crates/wcstringutil/src/lib.rs
#   https://github.com/fish-shell/fish-shell/blob/master/src/complete.rs
#   https://github.com/fish-shell/fish-shell/blob/master/src/reader/reader.rs
#   https://xon.sh/completers.html


# TODO: Add Fish-style search within the visible completion menu.
#
# Current behavior in Xonsh 0.23.6 with Prompt Toolkit 3.0.52:
#   - Ctrl-S starts forward incremental history search.
#   - If a completion menu is visible, that search does not filter its entries.
#   - Typing more of the command token recomputes/narrows completions, but there
#     is no separate query field for searching the already-visible menu.
#
# Desired behavior:
#   After opening the completion menu, a binding such as Ctrl-S should enter a
#   completion-search mode comparable to Fish's `pager-toggle-search`. Typed
#   search text should filter the menu without becoming part of the command
#   line; accepting a result should apply it to the original completion token.
#
# Scope and questions to answer after learning stock Xonsh completion:
#   - This requires Prompt Toolkit UI and keybinding work, not merely another
#     completion provider.
#   - Preserve normal Ctrl-S history search while no completion menu is active.
#   - Decide whether matching searches completion values, display labels,
#     descriptions, provider names, or some combination of them.
#   - Decide whether matching is substring, subsequence, fuzzy-ranked, or uses
#     the same matcher eventually chosen for command completion.
#   - Define Escape, Backspace-on-empty, Enter, Tab, Shift-Tab, Ctrl-C, and
#     completion-menu-dismissal behavior.
#   - Verify interaction with multiline input, Vi/Emacs modes, async completion,
#     mouse selection, completion refreshes, and the AI autosuggestion overlay.
#
# Tests should cover entering and leaving search mode, live filtering, accepting
# a result, restoring the untouched command buffer on cancellation, retaining
# Ctrl-S history search outside a completion menu, and zero/multiple results.
