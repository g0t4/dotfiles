## tab completion
# Ctrl+S style search of completion entries
# show static abbrs in completions (dynamic I don't think make sense to show unless it's just the end that varies?)
# show abbr description in completion entries

##### AI ideas
#
# [DONE] FIM via langchain like I do with neovim
# - [TODO] auto RAG matches:
#   repo contents global RAG search
#   and/or matches from shell history relevant to the current directory?
#
# TOOL calls too? in FIM? or no?
# - semantic_grep tool too? too via .rag/ dir (long term via any current dir as context to limit RAG matches)
#
# * MERGE HARNESS into SHELL
#   LET agent propose and/or run repeated command lines... serially or in parallel
#   ... basically ask a question, let it generate steps and let it also look at outputs, not just a one-shot answer
#    can have approval or a pause to read what it did between each step, or just fully auto

# TODO clear line (not new prompt) like ctrl+c I setup in fish (C+U,C+E like)
# TODO review fish custom bindings


###### DO NOT DO these from FISH setup:

# - partial path completion like: ~/r/g/g/d/<TAB> => ~/repos/github/g0t4/dotfiles
#   **use fzf pickers** INSTEAD
#   fzf picker is WAY faster 99% of the time than component by component abbrevaited spelling out and then tab.
#   plus `z` helps too and we already have that integrated with `z` from fish!
