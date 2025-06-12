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
