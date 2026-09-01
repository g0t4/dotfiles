"""Custom interactive keybindings for Xonsh's Prompt Toolkit shell."""

import os

from prompt_toolkit.filters import vi_insert_mode, vi_navigation_mode
from prompt_toolkit.key_binding.bindings.named_commands import get_by_name
from xonsh.dirstack import cd as _xonsh_cd
from xonsh.tools import print_above_prompt

from wes_directory_history import DirectoryHistory

# Terminal input contract:
# In iTerm2 Profiles > Keys, configure each Option key as Esc+, not Meta.
# Raw 8-bit Meta turns Alt-Shift-F into byte 0xC6, which Python's incremental
# UTF-8 decoder buffers as the start of a character until another key arrives.
# Esc+ produces the portable Escape then F sequence expected by Prompt Toolkit.
# This setting was verified with these Xonsh bindings, Fish, and Neovim.


_wes_directory_history = DirectoryHistory()


@events.on_chdir
def _wes_record_directory_change(olddir, newdir, **_):
    _wes_directory_history.record(olddir, newdir)


def _wes_refresh_prompt(event):
    """Repaint changed prompt fields without adding a prompt to history."""
    shell = __xonsh__.shell.shell
    prompter = getattr(shell, "prompter", None)
    if prompter is not None:
        ${...}["PROMPT_FIELDS"].reset()
        prompter.message = shell.prompt_tokens()
    event.app.invalidate()


def _wes_navigate_directory(event, *, forward):
    navigate = (
        _wes_directory_history.forward if forward else _wes_directory_history.back
    )
    def change_directory(target):
        _stdout, stderr, returncode = _xonsh_cd([target])
        if returncode:
            raise OSError(stderr.strip())

    try:
        changed = navigate(os.getcwd(), change_directory)
    except OSError as error:
        print_above_prompt(f"directory history: {error}")
        return
    if changed:
        _wes_refresh_prompt(event)


@events.on_ptk_create
def _wes_keybindings(bindings, prompter, **_):
    # Match Fish: on an empty command line Alt-Left/Right navigate a
    # bidirectional cwd timeline in place. With input present they retain
    # punctuation-aware word movement.
    @bindings.add("escape", "left", eager=True, save_before=lambda event: False)
    def _previous_directory_or_backward_word(event):
        if event.current_buffer.text:
            get_by_name("backward-word").handler(event)
        else:
            _wes_navigate_directory(event, forward=False)

    @bindings.add("escape", "right", eager=True, save_before=lambda event: False)
    def _next_directory_or_forward_word(event):
        if event.current_buffer.text:
            get_by_name("forward-word").handler(event)
        else:
            _wes_navigate_directory(event, forward=True)

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

    # Vim-mode additions -------------------------------------------------
    # Match Vim/Neovim: Ctrl-R redoes the most recently undone change in
    # normal mode. This intentionally replaces reverse history search there.
    @bindings.add(
        "c-r",
        filter=vi_navigation_mode,
        eager=True,
        save_before=lambda event: False,
    )
    def _vim_redo(event):
        event.current_buffer.redo()

    # * set propmt_toolkit's timeout keychord intervals
    # FYI same settings as in vim!
    # *** https://python-prompt-toolkit.readthedocs.io/en/master/pages/advanced_topics/key_bindings.html#timeouts
    #
    # import rich
    # rich.inspect(prompter.app)
    # rich.print(f"{prompter.app.timeoutlen=} {prompter.app.ttimeoutlen=}")
    #
    # * timeoutlen => default 1 (time to differentiate overlapping key bindings)
    #    A + AB defined => press A then have to wait a bit of time if we want to detect AB and not just fire A and ignore B (or chain with next keypress)
    #    1 IIAC == 1 second? (one difference, vim configures this in ms)
    prompter.app.timeoutlen = 0.3 # mirror neovim values in early.lua for now (I don't need 1 second!)
    #
    # ***** FYI this is all an attempt to make insert=>normal mode faster (one key press too) *****
    #       + not trigger alt(esc)+shift+letter keymaps when leaving insert mode
    #
    # * ttimeoutlen => default 0.5
    #   (for ansi escape codes IIUC)
    #   leave as-is for now, just double press Escape if it annoys you!
    # prompter.app.ttimeoutlen = 0.25 # LEAVE ALONE FOR NOW
    #
    # TODO maybe I should avoid using Escape (alt) for keypresses?
    #   these conflict for sure with my Shift+Alt+B/F/U etc fzf pickers, those could be remapped TBH
    #
    # FYI if you set both timeoutlen+ttimeoutlen==0 => escape instantly goes into normal mode (from insert mode) but then `dd` and keymaps like it won't work ;) cuz can't do the with zero lag (IIUC)


    # TODO wish list of keybinds (not urgent)
    #
    #  TODO make sure testing of key bind changes!
    # - Ctrl+A/X to _increment/decrement the nearest (on or after cursor) number just like in neovim
    # - surround keymaps (i.e. `ysiw` and `ysiW` and then what to wrap with...), test case:
    #   => `ysiw"` puts quotes around inner little word
    #   => `ysiW"` puts quotes around inner little word
    # - ?PRN? add test for timeoutlen change?

