"""Custom interactive keybindings for Xonsh's Prompt Toolkit shell."""


@events.on_ptk_create
def _wes_undo_keybinding(bindings, **_):
    # Prompt Toolkit already binds Ctrl+/ (reported as Ctrl+_) to undo.
    # Add the conventional Ctrl+Z spelling without replacing that binding.
    @bindings.add("c-z")
    def _undo(event):
        event.current_buffer.undo()
