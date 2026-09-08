"""Generated from fish/load_last_interactive_only/gitignore-wrappers.fish; edit Fish/Zsh and rerun the generator."""

from wes_abbreviations import abbr

SOURCE_FUNCTIONS = ('gitignores_for', 'append_gitignores_for', 'gitignore_init', 'commit_gitignores_for')


def register_gitignore_abbreviations():
    abbr('gi', 'gitignores_for')  # Source line 8
    abbr('gia', 'append_gitignores_for')  # Source line 13
    abbr('gii', 'gitignore_init')  # Source line 18
    abbr('gic', 'commit_gitignores_for')  # Source line 23
