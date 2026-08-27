"""Custom interactive keybindings for Xonsh's Prompt Toolkit shell."""

from prompt_toolkit.filters import vi_insert_mode
from prompt_toolkit.key_binding.bindings.named_commands import get_by_name

# Terminal input contract:
# In iTerm2 Profiles > Keys, configure each Option key as Esc+, not Meta.
# Raw 8-bit Meta turns Alt-Shift-F into byte 0xC6, which Python's incremental
# UTF-8 decoder buffers as the start of a character until another key arrives.
# Esc+ produces the portable Escape then F sequence expected by Prompt Toolkit.
# This setting was verified with these Xonsh bindings, Fish, and Neovim.


@events.on_ptk_create
def _wes_keybindings(bindings, **_):
    # Prompt Toolkit already binds Ctrl+/ (reported as Ctrl+_) to undo.
    # Add the conventional Ctrl+Z spelling without replacing that binding.
    @bindings.add("c-z", save_before=lambda event: False)
    def _undo(event):
        event.current_buffer.undo()

    # Esc+K remains the yank binding, freeing the conventional Ctrl+Y chord
    # for redo.
    @bindings.add("c-y", save_before=lambda event: False)
    def _redo(event):
        event.current_buffer.redo()

    # Prompt Toolkit provides this as Alt+. only in its Emacs bindings. Make
    # the same history argument cycling available while Xonsh is in Vi mode.
    @bindings.add("escape", ".", save_before=lambda event: False)
    def _yank_last_argument(event):
        event.current_buffer.yank_last_arg()

    # Prompt Toolkit's default Ctrl-W uses whitespace-delimited WORDs even in
    # Vi insert mode. Match Vim's small-word behavior so punctuation such as
    # dots and @ signs forms its own deletion boundary.
    @bindings.add(
        "c-w",
        filter=vi_insert_mode,
        eager=True,
        save_before=lambda event: False,
    )
    def _backward_kill_small_word(event):
        get_by_name("backward-kill-word").handler(event)

    @bindings.add("c-c", save_before=lambda event: False)
    def _clear_buffer_without_new_prompt(event):
        # Xonsh's default raises KeyboardInterrupt, which finishes this prompt
        # and draws another. Reset only the editor buffer so the existing
        # prompt stays in place. Foreground processes still receive SIGINT
        # directly from the terminal because Prompt Toolkit is not reading then.
        event.current_buffer.reset()
        event.app.invalidate()
