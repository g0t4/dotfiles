
# fish startup:
# - https://fishshell.com/docs/current/language.html#configuration
# - https://fishshell.com/docs/current/tutorial.html#tut-config

# TODO review feature flags: https://fishshell.com/docs/current/language.html#future-feature-flags
# TODO review options, i.e.:
set fish_greeting ""

if status is-interactive
    # status --is-login
    # Commands to run in interactive sessions can go here
end

# TODO => use ~/.config/fish/conf.d/ OR source here?


## WHY fish?
# PROS:
# - menu completion with tooltip (desc) for not just current menu selection but all current menu options
#   functions support descriptions
# - suggestions (inline) out of the box just work => that said I am more of a fan of expanding aliases but we shall see if suggests win me over
#   - I am already liking suggestions based on completions for things I've never done before
#   does it have a way to show multiple suggestsions like pwsh? might be nice to use one-off
# - syntax highlighting out of the box (just works)
# - exit codes show in default prompt (when failure) => FYI can do this in zsh too, and zsh can show exit codes before next prompt which is useful too
# - readable scripts
#   - query env: status is-interactive/is-login
# - man pages for builtins are direct (don't have to use man zshbuiltins)
# - abbreviations (expand) => equiv of my zsh ealias
#   - AND aliases (don't expand)
#   - cursor position in aliases, function to build expansion (dynamic), regex matching expansions
# - status builtin
#     status basename/dirname => of current script, AMEN
# CONS:


## TO READ UP ON / USEs
# - event handlers: https://fishshell.com/docs/current/language.html#event-handlers

## TO HABITUATE
# - type foo


## TMP to get me by while I migrate zsh ealiases:
abbr ta 'type -a'
abbr --set-cursor='!' gcmsg 'git commit -m "!"'
abbr gst 'git status'
abbr gaa 'git add --all'
abbr gdc 'git diff --cached'
abbr gd 'git diff'
abbr gap 'git add --patch'