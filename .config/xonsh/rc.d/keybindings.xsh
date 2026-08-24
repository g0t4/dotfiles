"""Custom interactive keybindings for Xonsh's Prompt Toolkit shell."""


@events.on_ptk_create
def _wes_undo_keybinding(bindings, **_):
    # Prompt Toolkit already binds Ctrl+/ (reported as Ctrl+_) to undo.
    # Add the conventional Ctrl+Z spelling without replacing that binding.
    @bindings.add("c-z", save_before=lambda event: False)
    def _undo(event):
        event.current_buffer.undo()

    @bindings.add("c-c", save_before=lambda event: False)
    def _clear_buffer_without_new_prompt(event):
        # Xonsh's default raises KeyboardInterrupt, which finishes this prompt
        # and draws another. Reset only the editor buffer so the existing
        # prompt stays in place. Foreground processes still receive SIGINT
        # directly from the terminal because Prompt Toolkit is not reading then.
        event.current_buffer.reset()
        event.app.invalidate()
