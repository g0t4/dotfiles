

# abbr hf 'history flush' # randomly this will not flush for 5+ minutes, not sure WTF is going on other than it is async and not guaranteed
#  so use at_exit=False to hopefully avoid this issue:
abbr hf '@.history.flush(at_exit=False)'
# TODO fix so `hp` is not helm pull? or just use `hm` to match fish's `history merge`?
abbr hp 'history pull --show-commands'

