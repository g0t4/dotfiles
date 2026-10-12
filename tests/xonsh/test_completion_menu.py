import test_setup

import asyncio
import os
import subprocess
import sys

import pytest
from prompt_toolkit import PromptSession
from prompt_toolkit.application.current import set_app
from prompt_toolkit.buffer import CompletionState
from prompt_toolkit.completion import Completion, Completer, WordCompleter
from prompt_toolkit.document import Document
from prompt_toolkit.enums import EditingMode
from prompt_toolkit.input import DummyInput
from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.key_binding.key_processor import KeyPress
from prompt_toolkit.keys import Keys
from prompt_toolkit.mouse_events import MouseEvent, MouseEventType, MouseButton
from prompt_toolkit.data_structures import Point
from prompt_toolkit.output import DummyOutput
from prompt_toolkit.shortcuts import CompleteStyle

from wes_completion_menu import (
    filter_completions,
    install_completion_menu,
    _FilterMenuControl,
)


def session():
    bindings = KeyBindings()
    prompter = PromptSession(
        input=DummyInput(),
        output=DummyOutput(),
        key_bindings=bindings,
        completer=WordCompleter([]),
    )
    env = {"COMPLETIONS_DISPLAY": "multi"}
    controller = install_completion_menu(prompter, bindings, env)
    prompter.default_buffer.document = Document("cat old tail", 7)
    candidates = [
        Completion("first", -3, display_meta="ordinary file"),
        Completion("second", -3, display_meta="universal log"),
        Completion("final", -3, display_meta="universal tooling"),
    ]
    prompter.default_buffer.complete_state = CompletionState(
        prompter.default_buffer.document, candidates
    )
    return prompter, controller, bindings


def feed(app, *keys):
    for key in keys:
        app.key_processor.feed(
            key
            if isinstance(key, KeyPress)
            else KeyPress(key, key if isinstance(key, str) and len(key) == 1 else "")
        )
    app.key_processor.process_keys()


def test_filter_prefers_values_and_scores_flexible_matches():
    choices = [
        Completion("other", display_meta="devtools universal"),
        Completion("tt_devtools_universal"),
        Completion("tt_u"),
    ]
    assert filter_completions(choices, "tt_u") == [choices[2], choices[1]]
    assert filter_completions(choices, "devuni") == [choices[1], choices[0]]
    assert filter_completions(choices, "notfound") == []
    assert filter_completions(choices, "") == choices
    assert filter_completions([Completion("value", display="FriendlyLabel")], "FL")


@pytest.mark.parametrize("mode", [EditingMode.EMACS, EditingMode.VI])
def test_typing_filter_and_accepting_keeps_query_out_of_multiline_command(mode):
    async def scenario():
        prompter, controller, _ = session()
        prompter.app.editing_mode = mode
        candidates = controller.source.complete_state.completions
        prompter.default_buffer.document = Document("echo first\ncat old tail", 18)
        prompter.default_buffer.complete_state = CompletionState(
            prompter.default_buffer.document, candidates
        )
        original = prompter.default_buffer.document
        submitted = []
        prompter.default_buffer.accept_handler = lambda buffer: submitted.append(
            buffer.text
        )
        with set_app(prompter.app):
            feed(prompter.app, Keys.ControlS)
            feed(prompter.app, *"universal")
            assert controller.query_buffer.text == "universal"
            assert prompter.default_buffer.document == original
            assert [c.text for c in controller.matches] == ["second", "final"]
            feed(prompter.app, Keys.ControlI)
            assert prompter.default_buffer.document == original
            feed(prompter.app, Keys.ControlM)
            assert prompter.default_buffer.text == "echo first\ncat final tail"
            assert not submitted
            assert not controller.active
            assert prompter.app.layout.has_focus(prompter.default_buffer)
            prompter.default_buffer.undo()
            assert prompter.default_buffer.document == original

    asyncio.run(scenario())


@pytest.mark.parametrize(
    "key,dismiss",
    [
        (Keys.Escape, False),
        (Keys.ControlS, False),
        (Keys.ControlC, True),
        (Keys.ControlH, False),
    ],
)
def test_cancellation_restores_original_document_and_choices(key, dismiss):
    async def scenario():
        prompter, controller, _ = session()
        original = controller.source.document
        controller.source.go_to_completion(1)
        with set_app(prompter.app):
            feed(prompter.app, Keys.ControlS)
            # A standalone Escape normally waits for an Alt chord; invoke the
            # processor's flush marker to represent the key timeout.
            feed(prompter.app, key)
            if key == Keys.Escape:
                from prompt_toolkit.key_binding.key_processor import _Flush

                feed(prompter.app, _Flush)
            assert not controller.active
            assert controller.source.document == original
            assert (controller.source.complete_state is None) == dismiss
            if not dismiss:
                assert (
                    controller.source.complete_state.completions
                    == controller.candidates
                )

    asyncio.run(scenario())


def test_zero_results_backspace_navigation_and_description_toggle():
    async def scenario():
        prompter, controller, _ = session()
        prompter.complete_style = CompleteStyle.MULTI_COLUMN
        with set_app(prompter.app):
            feed(prompter.app, Keys.ControlS, *"z")
            assert controller.matches == []
            feed(prompter.app, Keys.ControlM, Keys.Down, Keys.BackTab)
            assert controller.active
            assert controller.source.text == "cat old tail"
            feed(prompter.app, Keys.ControlH)
            assert len(controller.matches) == 3
            feed(prompter.app, Keys.Escape, "d")
            assert controller.active
            assert prompter.complete_style == CompleteStyle.COLUMN
            assert controller.env["COMPLETIONS_DISPLAY"] == "single"
            feed(prompter.app, Keys.Escape, "d")
            assert prompter.complete_style == CompleteStyle.MULTI_COLUMN
            feed(prompter.app, Keys.BackTab)
            assert (
                controller.query_buffer.complete_state.current_completion.text
                == "final"
            )

    asyncio.run(scenario())


def test_ctrl_s_outside_menu_retains_history_search_and_toggle_is_scoped():
    async def scenario():
        prompter, controller, bindings = session()
        prompter.default_buffer.complete_state = None
        with set_app(prompter.app):
            toggle = bindings.get_bindings_for_keys((Keys.Escape, "d"))[-1]
            assert not toggle.filter()
            feed(prompter.app, Keys.ControlS)
            assert prompter.app.layout.is_searching
            assert not controller.active

    asyncio.run(scenario())


def test_mouse_accepts_source_completion_without_overwriting_query():
    async def scenario():
        prompter, controller, _ = session()
        with set_app(prompter.app):
            controller.start()
            controller.query_buffer.text = "universal"
            control = _FilterMenuControl(controller)
            control.mouse_handler(
                MouseEvent(
                    Point(x=1, y=1),
                    MouseEventType.MOUSE_UP,
                    MouseButton.LEFT,
                    frozenset(),
                )
            )
            assert controller.source.text == "cat final tail"
            assert not controller.active

    asyncio.run(scenario())


def test_install_is_idempotent_and_focus_loss_closes_filter():
    async def scenario():
        prompter, controller, bindings = session()
        assert install_completion_menu(prompter, bindings, controller.env) is controller
        with set_app(prompter.app):
            controller.start()
            prompter.app.layout.focus(prompter.default_buffer)
            controller._check_focus(prompter.app)
            assert not controller.active
            assert controller.source.text == "cat old tail"

    asyncio.run(scenario())


def test_external_command_edits_supersede_filter_snapshot():
    async def scenario():
        prompter, controller, _ = session()
        with set_app(prompter.app):
            controller.start()
            controller.source.document = Document("echo voice", 10)
            controller._check_focus(prompter.app)
            assert not controller.active
            assert controller.source.text == "echo voice"
            assert prompter.app.layout.has_focus(controller.source)

    asyncio.run(scenario())


def test_search_freezes_collected_choices_while_async_completion_finishes():
    async def scenario():
        prompter, controller, _ = session()
        available = asyncio.Event()
        finish = asyncio.Event()

        class DelayedCompleter(Completer):
            def get_completions(self, document, complete_event):
                return iter(())

            async def get_completions_async(self, document, complete_event):
                yield Completion("early", -3)
                available.set()
                await finish.wait()
                yield Completion("late", -3)

        controller.source.complete_state = None
        controller.source.completer = DelayedCompleter()
        with set_app(prompter.app):
            task = asyncio.create_task(controller.source._async_completer())
            await available.wait()
            controller.start()
            finish.set()
            await task
            assert [c.text for c in controller.matches] == ["early"]
            controller.close()
            assert [c.text for c in controller.source.complete_state.completions] == [
                "early"
            ]

    asyncio.run(scenario())


@pytest.mark.parametrize("style", [CompleteStyle.COLUMN, CompleteStyle.MULTI_COLUMN])
def test_rendered_filter_menu_shows_choices_descriptions_and_separate_query(style):
    async def scenario():
        prompter, controller, _ = session()
        prompter.complete_style = style
        with set_app(prompter.app):
            controller.start()
            controller.query_buffer.text = "universal"
            prompter.app.renderer.render(prompter.app, prompter.app.layout)
            screen = prompter.app.renderer._last_screen
            rendered = "\n".join(
                "".join(row[x].char for x in sorted(row))
                for _, row in sorted(screen.data_buffer.items())
            )
            assert "Filter: universal" in rendered
            assert "2/3 choices" in rendered
            assert "second" in rendered
            assert "universal log" in rendered
            assert "cat old tail" in rendered

    asyncio.run(scenario())


@pytest.mark.parametrize("search_first", [True, False])
def test_real_xonsh_bindings_keep_filter_enter_and_escape_local(tmp_path, search_first):
    rc = test_setup.ROOT / ".config/xonsh/rc.d"
    script = tmp_path / "completion-menu.xsh"
    registration = [
        "_wes_completion_menu",
        "_wes_abbreviation_keybindings",
        "_wes_keybindings",
        "_wes_install_ai_autosuggester",
        "_wes_voice_keybinding",
    ]
    if not search_first:
        registration.reverse()
    setup = "\n".join(
        f"{name}(bindings=bindings, prompter=session)" for name in registration
    )
    script.write_text(f"""
source {rc / "abbreviations.xsh"}
source {rc / "completion-menu.xsh"}
source {rc / "keybindings.xsh"}
source {rc / "ai-autosuggest.xsh"}
source {rc / "voice-intent.xsh"}
# The config's version probe executes sys.argv[0], which is this test script.
current_xonsh_version = lambda: 'xonsh/0.24.2'
import asyncio
from prompt_toolkit import PromptSession
from prompt_toolkit.application.current import set_app
from prompt_toolkit.buffer import CompletionState
from prompt_toolkit.completion import Completion
from prompt_toolkit.document import Document
from prompt_toolkit.enums import EditingMode
from prompt_toolkit.input import DummyInput
from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.key_binding.key_processor import KeyPress, _Flush
from prompt_toolkit.keys import Keys
from prompt_toolkit.output import DummyOutput
from xonsh.shells.ptk_shell.key_bindings import load_xonsh_bindings

async def scenario():
    session = PromptSession(input=DummyInput(), output=DummyOutput(), editing_mode=EditingMode.VI)
    bindings = load_xonsh_bindings(session.app.key_bindings)
    session.key_bindings = bindings
    {setup.replace(chr(10), chr(10) + "    ")}
    controller = session._wes_completion_menu
    $COMPLETIONS_CONFIRM = True
    source = session.default_buffer
    source.document = Document('tt_u', 4)
    source.complete_state = CompletionState(source.document, [Completion('tt_devtools_universal', -4)])
    submitted = []
    source.accept_handler = lambda buffer: submitted.append(buffer.text)
    def feed(*keys):
        for key in keys:
            session.app.key_processor.feed(key if isinstance(key, KeyPress) else KeyPress(key))
        session.app.key_processor.process_keys()
    with set_app(session.app):
        feed(Keys.Escape, 'd')
        assert source.text == 'tt_u'
        assert source.complete_state is not None
        feed(Keys.ControlS, 'u')
        assert controller.query_buffer.text == 'u'
        feed(Keys.Escape, 'd')
        assert controller.active
        feed(Keys.ControlM)
        assert source.text == 'tt_devtools_universal'
        assert not submitted
        source.document = Document('tt_u', 4)
        source.complete_state = CompletionState(source.document, [Completion('tt_devtools_universal', -4)])
        feed(Keys.ControlS, Keys.Escape, _Flush)
        assert not controller.active
        assert source.text == 'tt_u'
    await session.app.cancel_and_wait_for_background_tasks()
asyncio.run(scenario())
""")
    completed = subprocess.run(
        [sys.executable, "-m", "xonsh", "--no-rc", str(script)],
        capture_output=True,
        text=True,
        env=os.environ | {"PYTHONPATH": str(rc.parent / "lib")},
    )
    assert completed.returncode == 0, completed.stderr
