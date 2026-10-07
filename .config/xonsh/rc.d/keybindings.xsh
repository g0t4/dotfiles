"""Custom interactive keybindings for Xonsh's Prompt Toolkit shell."""

from xonsh.built_ins import XSH

import os
import subprocess
import sys

from prompt_toolkit.filters import vi_insert_mode, vi_navigation_mode, vi_selection_mode
from prompt_toolkit.key_binding.bindings.named_commands import get_by_name
from xonsh.dirstack import cd as _xonsh_cd
from xonsh.tools import print_above_prompt
from xonsh.events import events
from prompt_toolkit.key_binding import KeyBindings, KeyPressEvent
from prompt_toolkit.keys import Keys
from prompt_toolkit.application import run_in_terminal
from prompt_toolkit.shortcuts import PromptSession
from prompt_toolkit.filters import Never
from prompt_toolkit.enums import EditingMode
from xonsh.formatter import format_source


from wes_directory_history import DirectoryHistory
from wes_history_tokens import history_token_search
from wes_logging import get_wes_logger
from wes_abbreviations import abbr
from wes_surround import (
    change_surround,
    delete_surround,
    normalize_pair,
    wrap_to_end,
    wrap_word,
)

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


# $XONSH_DEBUG_BREAKPOINT_ENGINE = 'ipdb' # default if not specified
# @.debug.replace_builtin_breakpoint() # take over @debug entirely
def start_debugger():
    # tab completion:
    # - confirmed these engines can tab complete: ipdb,
    #    IIUC execer and eval should work too
    # - some can't tab complete, b/c of how they're run:
    # - https://xon.sh/debug.html#tab-completion-in-callable-aliases
    #
    # @.debug.breakpoint('ipdb')
    @.debug.breakpoint(engine='ipdb', frame=@.imp.sys._getframe().f_back)
    # TODO setup ipdb (or w/e I choose) to work with vim like bindings (IIAC it's mostly all prompt_toolkit across backends?)
    # TODO how can I fix how the debugger mangles output of it and the current prompt?

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

    abbr("debugger", "start_debugger()")
    abbr("break", "start_debugger()")

    # cmd+ctrl+shift+D
    @bindings.add("\uE44B", save_before=lambda event: False)
    def _start_debugger(event: KeyPressEvent):
        # TODO look into extra chars injected when using this binding? and after you quit
        start_debugger()
        # event.current_buffer.insert_text("FOO") # moves cursor too
        # run_in_terminal(event.current_buffer.text)

    # TODO probably will settle on one of these in time and get rid of the other:
    # FYI ptk differentiates alt+i vs shift+alt+i
    # @bindings.add("escape", "i", save_before=lambda event: False) # alt+"i" (when using alt==esc)
    #
    # FYI new PUA unicode scheme is composable
    # @bindings.add("\ue0aa", "i", save_before=lambda event: False)
    #
    # ctrl+cmd+k using my new PUA+send_hex_code scheme so iTerm2 can receive rich key event info and project it to preserve it into my client apps
    # => see iterm2/keys/*.py
    @bindings.add("\uE694", save_before=lambda event: False)
    def _inspect_in_commandline(event: KeyPressEvent):
        event.current_buffer.text = _inspectify(event.current_buffer.text)
        event.current_buffer.cursor_position = len(event.current_buffer.text)  # cursor to end of buffer
        # event.current_buffer.insert_text("FOO") # moves cursor too
        # run_in_terminal(event.current_buffer.text)
    #
    # shift+alt+"i"
    @bindings.add("\uE495", save_before=lambda event: False)
    def _inspect_live(event: KeyPressEvent):
        code = _inspectify(event.current_buffer.text)
        print("\n", code)  # show what is evaluated (for scrollback purposes + to make sure I understand what's evaluated)
        func = lambda: XSH.execer.eval(code, globals(), locals())
        run_in_terminal(func)

    # Match Fish's reversible history-token-search-backward/forward. Unlike
    # Prompt Toolkit's yank_last_arg(), this visits every token, not only the
    # final argument of each command.
    @bindings.add("escape", ".", save_before=lambda event: False)
    @bindings.add("escape", "up", save_before=lambda event: False)
    def _history_token_backward(event: KeyPressEvent):
        history_token_search(event.current_buffer, forward=False)

    @bindings.add("escape", "down", save_before=lambda event: False)
    def _history_token_forward(event: KeyPressEvent):
        history_token_search(event.current_buffer, forward=True)

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

    @bindings.add("c-c")
    def _clear_buffer_without_new_prompt(event: KeyPressEvent):
        # Xonsh's default Ctrl-C raises KeyboardInterrupt, which finishes the prompt and draws another.
        # set text to nothing so this is undo-able
        event.current_buffer.text = ""
        event.app.invalidate()

    @bindings.add("escape", "a")
    def accept_and_hold(event):
        # mirror zsh's ctrl+a
        # accept and hold IIRC ...
        # run current command
        # + set next prompt cmdline to the same command and cursor position...
        # i.e. lets you easily re-run a command and tweak an argument
        buf = event.current_buffer
        pos = buf.cursor_position
        $XONSH_PROMPT_NEXT_CMD = (
            buf.text[:pos] + "<cursor>" + buf.text[pos:]
        )
        buf.validate_and_handle()

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

    @bindings.add("c-a")
    def _vim_increment(event: KeyPressEvent):
        buffer = event.current_buffer
        text = buffer.text
        pos = buffer.cursor_position
        import re
        m = re.search(r"-?\d+", text[pos:])
        if not m:
            m = re.search(r"-?\d+", text[:pos][::-1])
            if not m:
                return
            start = pos - m.end()
            end = pos - m.start()
        else:
            start = pos + m.start()
            end = pos + m.end()
        num_str = text[start:end]
        try:
            num = int(num_str)
        except ValueError:
            return
        count = int(event.arg or 1)
        new_num = str(num + count)
        buffer.text = text[:start] + new_num + text[end:]
        buffer.cursor_position = start + len(new_num)
        event.app.invalidate()

    def _invalidate(event):
        app = getattr(event, "app", None)
        if app is not None:
            app.invalidate()

    def _apply_buffer_text(event, new_text, new_pos):
        buffer = event.current_buffer
        buffer.text = new_text
        buffer.cursor_position = new_pos
        _invalidate(event)

    def _apply_wrap_word(event, *, key_index, big):
        buffer = event.current_buffer
        delim = event.key_sequence[key_index].key
        new_text, new_pos, changed = wrap_word(
            buffer.text, buffer.cursor_position, delim, big=big
        )
        if changed:
            _apply_buffer_text(event, new_text, new_pos)

    def wrap_selection(buffer, delim):
        # Wrap the active visual selection. Keeps the selection selected around
        # the inner expression: `echo |Hello World|` -> `echo "|Hello World|"`.
        selection_state = buffer.selection_state
        left, right = normalize_pair(delim)

        for start, end in buffer.document.selection_ranges():
            buffer.transform_region(start, end, lambda s: f"{left}{s}{right}")

        buffer.cursor_position += len(left)
        selection_state.original_cursor_position += len(left)
        buffer.selection_state = selection_state

    # ds<delim>: delete the surrounding pair nearest the cursor.
    @bindings.add("d", "s", Keys.Any, filter=vi_navigation_mode)
    def _vi_delete_surround(event: KeyPressEvent):
        buffer = event.current_buffer
        delim = event.key_sequence[2].key
        new_text, new_pos, changed = delete_surround(
            buffer.text, buffer.cursor_position, delim
        )
        if changed:
            _apply_buffer_text(event, new_text, new_pos)

    # cs<old><new>: swap the surrounding pair nearest the cursor.
    @bindings.add("c", "s", Keys.Any, Keys.Any, filter=vi_navigation_mode)
    def _vi_change_surround(event: KeyPressEvent):
        buffer = event.current_buffer
        old_delim = event.key_sequence[2].key
        new_delim = event.key_sequence[3].key
        new_text, new_pos, changed = change_surround(
            buffer.text, buffer.cursor_position, old_delim, new_delim
        )
        if changed:
            _apply_buffer_text(event, new_text, new_pos)

    # S<delim>: wrap the current visual selection.
    @bindings.add("S", Keys.Any, filter=vi_selection_mode)
    def _vi_surround(event: KeyPressEvent):
        buffer = event.current_buffer
        delim = event.key_sequence[1].key
        wrap_selection(buffer, delim)

    # yst<delim>: "you surround this" - wrap the word under/after the cursor.
    @bindings.add("y", "s", "t", Keys.Any, filter=vi_navigation_mode)
    def _vi_ys_surround_this(event: KeyPressEvent):
        _apply_wrap_word(event, key_index=3, big=False)

    # ysiw<delim>: wrap the inner small word (alnum + underscore).
    @bindings.add("y", "s", "i", "w", Keys.Any, filter=vi_navigation_mode)
    def _vi_ys_surround_inner_word(event: KeyPressEvent):
        _apply_wrap_word(event, key_index=4, big=False)

    # ysiW<delim>: wrap the inner big word (non-whitespace run).
    @bindings.add("y", "s", "i", "W", Keys.Any, filter=vi_navigation_mode)
    def _vi_ys_surround_inner_big_word(event: KeyPressEvent):
        _apply_wrap_word(event, key_index=4, big=True)

    # ys$<delim>: wrap from the cursor to the end of the buffer.
    @bindings.add("y", "s", "$", Keys.Any, filter=vi_navigation_mode)
    def _vi_ys_surround_to_end(event: KeyPressEvent):
        buffer = event.current_buffer
        delim = event.key_sequence[3].key
        new_text, new_pos, changed = wrap_to_end(
            buffer.text, buffer.cursor_position, delim
        )
        if changed:
            _apply_buffer_text(event, new_text, new_pos)

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
    # - surround keymaps are done (see above):
    #   => `ds(` deletes the parens around the cursor
    #   => `cs("` swaps parens for quotes around the cursor
    #   => `S(` wraps the visual selection in parens
    #   => `yst"` / `ysiw"` wrap the word under the cursor in quotes
    #   => `ysiW"` wraps the inner big word
    #   => `ys$"` wraps from the cursor to the end of the buffer
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

abbr("pua", "doctor_list_pua_keys()")
def doctor_list_pua_keys():
    env f"PYTHONPATH={$WES_DOTFILES}/iterm2/keys" \
        f"{$WES_DOTFILES}/.venv/bin/python3" \
        "-c" \
        f"import custom_keys; custom_keys.list_pua_keys()" list_pua_keys

abbr("doctor_list_iterm_keys", "doctor_list_iterm_keys()")
def doctor_list_iterm_keys():
    env f"PYTHONPATH={$WES_DOTFILES}/iterm2/keys" \
        f"{$WES_DOTFILES}/.venv/bin/python3" \
        f"{$WES_DOTFILES}/iterm2/keys/list_iterm2_global_keys.py"

abbr('showkey', 'doctor_wes_showkey()')
def doctor_wes_showkey():
    env f"PYTHONPATH={$WES_DOTFILES}/iterm2/keys" \
        f"{$WES_DOTFILES}/.venv/bin/python3" \
        f"{$WES_DOTFILES}/iterm2/keys/wes_showkey.py"


def current_xonsh_version():
    version = subprocess.check_output(
        [sys.argv[0], "--version"],
        text=True,
    ).strip()
    return version
