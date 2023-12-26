ealias cat="bat" # let's see how I feel about this! this now works at any command position b/c I fixed when to trigger ealias expansion (not just first word of command)

ealias batp="bat --plain" # -p also
  ealias batpp="bat --plain --paging never" # same as --style=plain --pager=never

## diagnostic
ealias batd="bat --diagnostic" # print diagnostic report for troubleshooting (think brew doctor)
ealias batcc="bat cache --clear"
