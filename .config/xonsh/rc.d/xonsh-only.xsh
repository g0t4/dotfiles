from wes_abbreviations import abbr

if Path(__file__).name < "xonsh-only.xsh":
    raise RuntimeError("xonsh-only.xsh must be named so it loads later on to override with xonsh specific abbrs")


def register_xonsh_only_abbrs():
    # abbr hf 'history flush' # randomly this will not flush for 5+ minutes, not sure WTF is going on other than it is async and not guaranteed
    #  so use at_exit=False to hopefully avoid this issue:
    abbr('hf', '@.history.flush(at_exit=False)')

    abbr('hp', 'history pull --show-commands')


register_xonsh_only_abbrs()
