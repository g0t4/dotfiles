from xonsh.built_ins import XSH
from xonsh.events import events

from prompt_toolkit.keys import Keys

def dump_keymaps():
    return XSH.shell.shell.prompter.app.key_bindings.bindings


# app = XSH.shell.prompter.app
# bindings = app.key_bindings.bindings
#
# for binding in bindings:
#     keys = " ".join(map(str, binding.keys))
#     handler = getattr(binding.handler, "__name__", repr(binding.handler))
#     if "control" in keys.lower():
#         print(keys, handler)

def what_shell():
    return "xonsh"

# @events.on_ptk_create
# def _wes_learn(bindings, **_):
#     print("_wes_learn bindings registered")
#
#     @bindings.add('a', 'b')
#     def _(event):
#         " Do something if 'a' is pressed and then 'b' is pressed. "
#         print("this is why timeoutlen matters :)")

