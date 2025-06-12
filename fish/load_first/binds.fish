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

