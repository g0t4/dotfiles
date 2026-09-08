"""Generated from zsh/compat_fish/gh.zsh; edit Fish/Zsh and rerun the generator."""

from wes_abbreviations import abbr

SOURCE_FUNCTIONS = ()


def register_gh_abbreviations():
    abbr('ghr', 'gh reference')  # Source line 8
    abbr('ghh', 'gh reference')  # Source line 9
    abbr('ghi', 'gh issue')  # Source line 12
    abbr('ghils', 'gh issue list')  # Source line 14
    abbr('ghis', 'gh issue list --search Q')  # Source line 16
    abbr('ghisw', 'gh issue list --web --search Q ')  # Source line 17
    abbr('ghiw', 'gh issue list --web')  # Source line 18
    abbr('ghs', 'gh search')  # Source line 23
    abbr('ghsr', 'gh search repos')  # Source line 24
    abbr('ghsro', 'gh search repos --owner=')  # Source line 25
    abbr('ghsi', 'gh search issues')  # Source line 26
    abbr('ghsio', 'gh search issues --owner=')  # Source line 27
    abbr('ghsir', 'gh search issues --repo=')  # Source line 28
    abbr('ghsp', 'gh search prs')  # Source line 29
    abbr('ghspo', 'gh search prs --owner=')  # Source line 30
    abbr('ghspr', 'gh search prs --repo=')  # Source line 31
    abbr('ghsc', 'gh search code')  # Source line 32
    abbr('ghsco', 'gh search code --owner=')  # Source line 33
    abbr('ghscr', 'gh search code --repo=')  # Source line 34
    abbr('ghscof', 'gh search code --filename --owner')  # Source line 35
    abbr('ghscm', 'gh search commits')  # Source line 36
    abbr('ghscmo', 'gh search commits --owner=')  # Source line 37
    abbr('ghscmr', 'gh search commits --repo=')  # Source line 38
    abbr('ghwf', 'gh workflow')  # Source line 42
    abbr('ghwfl', 'gh workflow list')  # Source line 43
    abbr('ghwfr', 'gh workflow run')  # Source line 44
    abbr('ghwfv', 'gh workflow view')  # Source line 45
    abbr('ghwfe', 'gh workflow enable')  # Source line 46
    abbr('ghwfd', 'gh workflow disable')  # Source line 47
    abbr('ghrun', 'gh run')  # Source line 50
    abbr('ghrunr', 'gh run rerun')  # Source line 51
    abbr('ghrunl', 'gh run list')  # Source line 52
    abbr('ghrunc', 'gh run cancel')  # Source line 53
    abbr('ghrunrm', 'gh run delete')  # Source line 54
    abbr('ghrunv', 'gh run view')  # Source line 56
    abbr('ghrunw', 'gh run watch')  # Source line 57
    abbr('ghe', 'gh extension')  # Source line 64
    abbr('ghel', 'gh extension list')  # Source line 65
    abbr('gheb', 'gh extension browse')  # Source line 66
    abbr('ghes', 'gh extension search')  # Source line 67
    abbr('ghei', 'gh extension install')  # Source line 68
    abbr('gherm', 'gh extension remove')  # Source line 69
    abbr('ghw', 'gh repo view --web')  # Source line 73
    abbr('ghb', 'gh repo view --branch')  # Source line 74
    abbr('ghwb', 'gh repo view --web --branch')  # Source line 75
    abbr('ghv', 'gh repo view')  # Source line 76
    abbr('ghrd', 'gh repo delete')  # Source line 77
    abbr('ghrl', 'gh repo list --no-archived --limit 1000')  # Source line 78
    abbr('ghcoe', 'gh copilot explain')  # Source line 81
    abbr('ghcos', 'gh copilot suggest -t shell')  # Source line 82
