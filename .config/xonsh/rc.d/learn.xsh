from xonsh.built_ins import XSH

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
