import rich
from prompt_toolkit.application import run_in_terminal
from prompt_toolkit.filters import Never
from prompt_toolkit.key_binding import KeyBindings, KeyPressEvent
from prompt_toolkit.keys import Keys
from prompt_toolkit.shortcuts import PromptSession
from xonsh.built_ins import XSH
from xonsh.events import events

bindings = XSH.shell.shell.prompter.app.key_bindings
for b in bindings.bindings:
    if (
        b.keys == (Keys.Escape,)
        and b.handler.__name__ == "_back_to_navigation"
    ):
        b.eager = Never()


@events.on_ptk_create
def _wes_keybindings(bindings: KeyBindings, prompter: PromptSession, **_):

    # TODO probably will settle on one of these in time and get rid of the other:
    # FYI ptk differentiates alt+i vs shift+alt+i
    # alt+"i"
    @bindings.add("escape", "i", save_before=lambda event: False)
    def _inspect_in_commandline(event: KeyPressEvent):
        event.current_buffer.text = f"rich.inspect({event.current_buffer.text})"
        event.current_buffer.cursor_position = len(event.current_buffer.text)  # cursor to end of buffer
        # event.current_buffer.insert_text("FOO") # moves cursor too
        # run_in_terminal(event.current_buffer.text)
    #
    # shift+alt+"i"
    @bindings.add("escape", "I", save_before=lambda event: False)
    def _inspect_live(event: KeyPressEvent):
        cmd_line = event.current_buffer.text
        # how do I compile it into python and wrap with inspect?
        code = f"rich.inspect({cmd_line})"
        print("\n", code)
        # run it live
        func = lambda: XSH.execer.eval(code, globals(), locals())
        run_in_terminal(func)

