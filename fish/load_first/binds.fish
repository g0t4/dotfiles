# * ok lets do it! I want vi bindings!
# PRN move this elsewhere?
# https://fishshell.com/docs/current/interactive.html#vi-mode
fish_vi_key_bindings
function bind_both_modes_default_and_insert
    # FYI this is for using vi-mode, to bind in both normal and default modes
    #  default also works in non-vi-mode (emacs like)
    #  NOTE default == normal in vi-mode
    bind -M default $argv
    bind -M insert $argv
end

# * idea... to simulate my favorite vim motions/command combos
#   unfortunately, "word" doesn't match between fish and vim... fish treats - as a boundary too
#   so I am going with word == bigword
bind -M default d,i,w _diw
function _diw
    commandline -f backward-bigword
    commandline -f kill-bigword
end

bind -M default c,i,w _ciw
function _ciw
    commandline -f backward-bigword
    commandline -f kill-bigword
    set fish_bind_mode insert
    # alternatively use `bind -m insert` to switch modes after the bound function completes
end

# * half baked ideas:
#
bind -M default v,i,w _viw
function _viw
    set fish_bind_mode visual
    commandline -f backward-bigword
    commandline -f begin-selection
    commandline -f forward-bigword
    # this does select the text, but I am not sure what else I can do with it?
end
#
# function _copy_selection
#     set -l buf (commandline)
#     set -l start (commandline --selection-start)
#     set -l end (commandline --selection-end)
#
#     echo $start/$end
#
#
#     if test $start -lt 0
#         return # no selection
#     end
#
#     set -l selection (string sub --start (math $start) --end (math $end + 1) -- "$buf")
#
#     echo -n $selection pbcopy # use xclip/wl-copy if not macOS
#     commandline -f cancel
# end
#
# copy word? (but don't delete/kill it)
# bind -M default y,i,w _yiw
# function _yiw
#     set fish_bind_mode visual
#     commandline -f backward-bigword
#     commandline -f begin-selection
#     commandline -f forward-bigword
#     _copy_selection
# end
#

# TODO! should I move these bindings to nvim too?!
# undo/redo should work in insert mode too
bind_both_modes_default_and_insert -M insert ctrl-z undo # TODO ctrl-z not working in normal mode, IS ok in insert mode now?!
bind_both_modes_default_and_insert -M insert ctrl-Z redo
# FTR, fish_default_key_bindings has the following, of which I am only mapping ctrl-z/Z for now:
#
# bind | grep -i undo
#   bind --preset ctrl-/ undo
#   bind --preset ctrl-_ undo
#   bind --preset ctrl-z undo
#
# bind | grep -i undo
#   bind --preset ctrl-/ undo
#   bind --preset ctrl-_ undo
#   bind --preset ctrl-z undo
