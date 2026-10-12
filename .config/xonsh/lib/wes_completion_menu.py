"""Search collected Tab completions without editing the command line."""

from __future__ import annotations

from prompt_toolkit.buffer import Buffer, CompletionState
from prompt_toolkit.completion import Completion
from prompt_toolkit.filters import Condition, has_focus
from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.key_binding.vi_state import InputMode
from prompt_toolkit.keys import Keys
from prompt_toolkit.layout.containers import (
    ConditionalContainer,
    Float,
    FloatContainer,
    HSplit,
    Window,
)
from prompt_toolkit.layout.controls import BufferControl
from prompt_toolkit.layout.dimension import Dimension
from prompt_toolkit.layout.menus import (
    CompletionsMenu,
    CompletionsMenuControl,
    MultiColumnCompletionsMenu,
)
from prompt_toolkit.mouse_events import MouseEventType
from prompt_toolkit.layout.processors import AfterInput, BeforeInput
from prompt_toolkit.shortcuts import CompleteStyle

from wes_abbreviations import completion_match_key


def filter_completions(completions: list[Completion], query: str) -> list[Completion]:
    """Prefer value matches over label/description matches; retain empty order."""
    if not query:
        return list(completions)
    ranked = []
    for index, completion in enumerate(completions):
        for field, text in enumerate(
            (completion.text, completion.display_text, completion.display_meta_text)
        ):
            key = completion_match_key(text, query)
            if key is not None:
                ranked.append(((field, key[:2], index), completion))
                break
    return [completion for _, completion in sorted(ranked, key=lambda row: row[0])]


class _FilterBuffer(Buffer):
    """Menu navigation selects candidates without replacing the filter query."""

    def __init__(self, owner):
        self.owner = owner
        super().__init__(name="wes-completion-filter", multiline=False)

    def go_to_completion(self, index):
        if self.complete_state is not None:
            self.complete_state.go_to_index(index)
            self.on_completions_changed.fire()

    def apply_completion(self, completion):
        self.owner.accept(completion)


class _FilterMenuControl(CompletionsMenuControl):
    def __init__(self, owner):
        super().__init__()
        self.owner = owner

    def mouse_handler(self, event):
        if event.event_type == MouseEventType.MOUSE_UP:
            completions = self.owner.matches
            if 0 <= event.position.y < len(completions):
                self.owner.accept(completions[event.position.y])
            return None
        return super().mouse_handler(event)


def _prompt_float(container):
    if isinstance(container, FloatContainer) and isinstance(container.content, HSplit):
        return container
    for child in container.get_children():
        found = _prompt_float(child)
        if found is not None:
            return found
    return None


class CompletionMenuSearch:
    def __init__(self, prompter, bindings, env):
        self.prompter = prompter
        self.app = prompter.app
        self.source = prompter.default_buffer
        self.env = env
        self.active = False
        self.original_input_mode = None
        self.original_document = None
        self.candidates = []
        self.matches = []
        self.query_buffer = _FilterBuffer(self)
        self.query_buffer.on_text_changed += self._filter_changed
        self.query_buffer.on_cursor_position_changed += self._filter_changed
        self.query_bindings = KeyBindings()
        self.control = BufferControl(
            buffer=self.query_buffer,
            key_bindings=self.query_bindings,
            input_processors=[BeforeInput("Filter: "), AfterInput(self._status)],
            focus_on_click=True,
        )
        self._bind_keys(bindings)

    def _status(self):
        return [
            (
                "class:completion-menu.meta",
                f"  {len(self.matches)}/{len(self.candidates)} choices",
            )
        ]

    def install_layout(self):
        container = _prompt_float(self.app.layout.container)
        if container is None:
            return False
        visible = Condition(lambda: self.active)
        for window in self.app.layout.find_all_windows():
            if (
                isinstance(window.content, BufferControl)
                and window.content.buffer is self.source
            ):
                original_height = window.height
                # Move the menu's reserved space below the filter field, so a
                # tall results menu cannot float over the command itself.
                window.height = (
                    lambda: Dimension()
                    if self.active
                    else (
                        original_height()
                        if callable(original_height)
                        else original_height
                    )
                )
                break
        container.content.children.append(
            ConditionalContainer(
                HSplit(
                    [
                        Window(self.control, height=1, wrap_lines=False),
                        Window(
                            height=lambda: max(1, self.prompter.reserve_space_for_menu)
                        ),
                    ]
                ),
                visible,
            )
        )
        column_mode = Condition(
            lambda: self.prompter.complete_style == CompleteStyle.MULTI_COLUMN
        )
        focused = visible & has_focus(self.query_buffer)
        single = CompletionsMenu(
            max_height=16, scroll_offset=1, extra_filter=focused & ~column_mode
        )
        single.content.content = _FilterMenuControl(self)
        multi = MultiColumnCompletionsMenu(
            show_meta=True, extra_filter=focused & column_mode
        )
        for menu in (single, multi):
            container.floats.append(
                Float(xcursor=True, ycursor=True, transparent=True, content=menu)
            )
        self.app.before_render += self._check_focus
        return True

    def _check_focus(self, _app):
        # Clicking the command or starting another UI must not leave a stale
        # filter session behind. Do not steal focus back from that UI.
        if self.active and self.source.document != self.original_document:
            # Voice input or another background editor supersedes our snapshot.
            self.close(
                dismiss=True,
                restore=False,
                focus=self.app.layout.has_focus(self.query_buffer),
            )
        elif self.active and (
            self.app.is_done or not self.app.layout.has_focus(self.query_buffer)
        ):
            self.close(focus=False)

    def start(self):
        state = self.source.complete_state
        if not state or not state.completions:
            return
        self.original_document = state.original_document
        self.candidates = list(state.completions)
        # Replace the state to stop any in-flight completion generator. The
        # filter operates on the choices already collected by Tab.
        self.source.go_to_completion(None)
        self.source.complete_state = CompletionState(
            self.original_document, list(self.candidates)
        )
        self.query_buffer.reset()
        self.original_input_mode = self.app.vi_state.input_mode
        self.app.vi_state.input_mode = InputMode.INSERT
        self.active = True
        self._filter_changed(self.query_buffer)
        self.app.layout.focus(self.control)
        self.app.invalidate()

    def _filter_changed(self, _buffer):
        if not self.active:
            return
        self.matches = filter_completions(self.candidates, self.query_buffer.text)
        self.query_buffer.complete_state = CompletionState(
            self.query_buffer.document,
            self.matches,
            0 if self.matches else None,
        )
        self.query_buffer.on_completions_changed.fire()
        self.app.invalidate()

    def close(self, *, dismiss=False, focus=True, restore=True):
        if not self.active:
            return
        self.active = False
        self.app.vi_state.input_mode = self.original_input_mode
        self.query_buffer.complete_state = None
        if restore:
            self.source.document = self.original_document
            self.source.complete_state = (
                None
                if dismiss
                else CompletionState(
                    self.original_document,
                    list(self.candidates),
                )
            )
        self.source.on_completions_changed.fire()
        if focus:
            self.app.layout.focus(self.source)
        self.app.invalidate()

    def accept(self, completion=None):
        state = self.query_buffer.complete_state
        if completion is None:
            completion = state.current_completion if state else None
        if completion is None:
            return
        self.close(dismiss=True)
        self.source.save_to_undo_stack()
        self.source.apply_completion(completion)

    def toggle_layout(self):
        mode = (
            "single"
            if self.prompter.complete_style == CompleteStyle.MULTI_COLUMN
            else "multi"
        )
        self.env["COMPLETIONS_DISPLAY"] = mode
        self.prompter.complete_style = (
            CompleteStyle.COLUMN if mode == "single" else CompleteStyle.MULTI_COLUMN
        )
        self.app.invalidate()

    def _bind_keys(self, bindings):
        menu_open = Condition(
            lambda: (
                self.app.layout.has_focus(self.source)
                and bool(
                    self.source.complete_state
                    and self.source.complete_state.completions
                )
            )
        )
        # Xonsh installs eager Vi Escape handlers. Keep them outside completion
        # menus, but allow Escape versus Alt-D to be distinguished in a menu.
        for binding in bindings.bindings:
            if binding.keys == (Keys.Escape,):
                binding.filter &= ~has_focus(self.query_buffer) & ~menu_open

        @bindings.add("escape", filter=menu_open, save_before=lambda event: False)
        def dismiss_menu(event):
            self.source.cancel_completion()

        @bindings.add("c-s", filter=menu_open, save_before=lambda event: False)
        def start_filter(event):
            self.start()

        @bindings.add("escape", "d", filter=menu_open, save_before=lambda event: False)
        @self.query_bindings.add("escape", "d", save_before=lambda event: False)
        def toggle_descriptions(event):
            self.toggle_layout()

        @self.query_bindings.add("c-s")
        @self.query_bindings.add("escape")
        def cancel_filter(event):
            self.close()

        @self.query_bindings.add("c-c")
        def dismiss_filter(event):
            self.close(dismiss=True)

        @self.query_bindings.add("c-h")
        def backspace(event):
            if not self.query_buffer.text:
                self.close()
            else:
                self.query_buffer.delete_before_cursor()

        @self.query_bindings.add("c-m")
        @self.query_bindings.add("c-j")
        def accept_filter(event):
            self.accept()

        @self.query_bindings.add("down")
        @self.query_bindings.add("c-i")
        def next_choice(event):
            self._navigate(1)

        @self.query_bindings.add("up")
        @self.query_bindings.add("s-tab")
        def previous_choice(event):
            self._navigate(-1)

    def _navigate(self, direction):
        if self.matches:
            state = self.query_buffer.complete_state
            index = state.complete_index if state.complete_index is not None else 0
            self.query_buffer.go_to_completion((index + direction) % len(self.matches))


def install_completion_menu(prompter, bindings, env):
    if prompter is None:
        return None
    existing = getattr(prompter, "_wes_completion_menu", None)
    if existing is not None:
        return existing
    controller = CompletionMenuSearch(prompter, bindings, env)
    if not controller.install_layout():
        return None
    prompter._wes_completion_menu = controller
    return controller
