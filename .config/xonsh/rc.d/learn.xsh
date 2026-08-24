from prompt_toolkit.keys import Keys

def dump_keymaps():
    return __xonsh__.shell.shell.prompter.app.key_bindings.bindings


# app = __xonsh__.shell.prompter.app
# bindings = app.key_bindings.bindings
#
# for binding in bindings:
#     keys = " ".join(map(str, binding.keys))
#     handler = getattr(binding.handler, "__name__", repr(binding.handler))
#     if "control" in keys.lower():
#         print(keys, handler)
