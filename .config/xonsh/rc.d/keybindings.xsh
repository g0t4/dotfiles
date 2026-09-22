"""Custom interactive keybindings for Xonsh's Prompt Toolkit shell."""

from xonsh.built_ins import XSH

import os
import subprocess
import sys

from prompt_toolkit.filters import vi_insert_mode, vi_navigation_mode
from prompt_toolkit.key_binding.bindings.named_commands import get_by_name
from xonsh.dirstack import cd as _xonsh_cd
from xonsh.tools import print_above_prompt
from xonsh.events import events
from prompt_toolkit.key_binding import KeyBindings, KeyPressEvent
from prompt_toolkit.keys import Keys
from prompt_toolkit.application import run_in_terminal
from prompt_toolkit.shortcuts import PromptSession
from prompt_toolkit.filters import Never
from xonsh.formatter import format_source


from wes_directory_history import DirectoryHistory
from wes_logging import get_wes_logger
from wes_abbreviations import abbr

log = get_wes_logger(__name__)

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
    shell = XSH.shell.shell
    prompter = getattr(shell, "prompter", None)
    if prompter is not None:
        $PROMPT_FIELDS.reset()
        prompter.message = shell.prompt_tokens()
    event.app.invalidate()


def _wes_navigate_directory_history_intra_prompt(event, *, forward):
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
def _wes_keybindings(bindings: KeyBindings, prompter: PromptSession, **_):

    # Match Fish prevd-or-backward-word/nextd-or-forward-word
    # On an _Empty Command Line_ Alt-Left/Right navigate cwd history in place
    # With input present they retain punctuation-aware word movement.
    @bindings.add("escape", "left", eager=True, save_before=lambda event: False)
    def _previous_directory_or_backward_word(event):
        has_input = bool(event.current_buffer.text)
        if has_input:
            get_by_name("backward-word").handler(event)
        else:
            _wes_navigate_directory_history_intra_prompt(event, forward=False)

    @bindings.add("escape", "right", eager=True, save_before=lambda event: False)
    def _next_directory_or_forward_word(event):
        has_input = bool(event.current_buffer.text)
        if has_input:
            get_by_name("forward-word").handler(event)
        else:
            _wes_navigate_directory_history_intra_prompt(event, forward=True)

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

    def _inspectify(expression: str) -> str:
        expression = format_source(expression).strip()
        return f"rich.inspect({expression})"

    # TODO probably will settle on one of these in time and get rid of the other:
    # FYI ptk differentiates alt+i vs shift+alt+i
    # @bindings.add("escape", "i", save_before=lambda event: False) # alt+"i" (when using alt==esc)
    #
    # FYI new PUA unicode scheme is composable
    # @bindings.add("\ue0aa", "i", save_before=lambda event: False)
    #
    # ctrl+cmd+k using my new PUA+send_hex_code scheme so iTerm2 can receive rich key event info and project it to preserve it into my client apps
    # => see iterm2/keys/*.py
    @bindings.add("\uE084", save_before=lambda event: False)
    def _inspect_in_commandline(event: KeyPressEvent):
        event.current_buffer.text = _inspectify(event.current_buffer.text)
        event.current_buffer.cursor_position = len(event.current_buffer.text)  # cursor to end of buffer
        # event.current_buffer.insert_text("FOO") # moves cursor too
        # run_in_terminal(event.current_buffer.text)
    #
    # shift+alt+"i"
    @bindings.add("\uE085", save_before=lambda event: False)
    def _inspect_live(event: KeyPressEvent):
        code = _inspectify(event.current_buffer.text)
        print("\n", code) # show what is evaluated (for scrollback purposes + to make sure I understand what's evaluated)
        func = lambda: XSH.execer.eval(code, globals(), locals())
        run_in_terminal(func)

    # Prompt Toolkit provides this as Alt+. only in its Emacs bindings. Make
    # the same history argument cycling available while Xonsh is in Vi mode.
    @bindings.add("escape", ".", save_before=lambda event: False)
    @bindings.add("escape", "up", save_before=lambda event: False)
    def _yank_last_argument(event: KeyPressEvent):
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
    prompter.app.timeoutlen = 0.3  # mirror neovim values in early.lua for now (I don't need 1 second!)
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

    def low_level_observe_keyboard_events():
        # low level hook to inspect keyboard inputs (b/c `bindings.add(Keys.Any)` barely captures anything)
        app = prompter.app

        original_read_keys = app.input.read_keys

        def read_keys():
            keys = original_read_keys()
            for k in keys:
                log.info(f"Key: {k.key}, Data: {k.data}")
            return keys

        app.input.read_keys = read_keys

    low_level_observe_keyboard_events()

    # def _keypress_tee_from_codex(prompter):
    #     """ shows some of the same info as my low_level_observe_keyboard_events above """
    #     if prompter is None:
    #         return
    #     key_processor = prompter.app.key_processor
    #     if getattr(key_processor, "_wes_keypress_tee_installed", False):
    #         return
    #     original_feed_multiple = key_processor.feed_multiple
    #
    #     def feed_multiple(key_presses, first=False):
    #         keys = list(key_presses)
    #         if bool(@.env.get("XONSH_KEYPRESS_DEBUG", False)):
    #             log.info(
    #                 "key_feed first=%s keys=%r",
    #                 first,
    #                 [
    #                     {"key": str(key_press.key), "data": repr(key_press.data)}
    #                     for key_press in keys
    #                 ],
    #             )
    #         return original_feed_multiple(keys, first=first)
    #
    #     key_processor.feed_multiple = feed_multiple
    #     key_processor._wes_keypress_tee_installed = True

    def override_v0_24_eager_escape_in_vi_mode():
        # FYI this is not needed in v0.23, just v0.24
        version = current_xonsh_version()
        if version.startswith("xonsh/0.23"):
            return
        if not version.startswith("xonsh/0.24"):
            print(f"""applying eager escape fix to a version ({version=}) of xonsh that may not need it?
            next major version is a good time to check if my 0.24 fix is still necessary...
            update warning code accordingly...""")
            return
        for b in bindings.bindings:
            if (
                b.keys == (Keys.Escape,)
                and b.handler.__name__ == "_back_to_navigation"
            ):
                b.eager = Never()

    override_v0_24_eager_escape_in_vi_mode()

abbr("pua", "list_pua_keys()")
def list_pua_keys():
    env f"PYTHONPATH={$WES_DOTFILES}/iterm2/keys" \
        f"{$WES_DOTFILES}/.venv/bin/python3" \
        "-c" \
        f"import custom_keys; custom_keys.list_pua_keys()" list_pua_keys

abbr("iterm_keys", "list_iterm_keys()")
def list_iterm_keys():
    env f"PYTHONPATH={$WES_DOTFILES}/iterm2/keys" \
        f"{$WES_DOTFILES}/.venv/bin/python3" \
        f"list_iterm2_global_keys.py"

def wes_showkey():
    env f"PYTHONPATH={$WES_DOTFILES}/iterm2/keys" \
        f"{$WES_DOTFILES}/.venv/bin/python3" \
        f"-m wes_showkey"

def current_xonsh_version():
    version = subprocess.check_output(
        [sys.argv[0], "--version"],
        text=True,
    ).strip()
    return version
