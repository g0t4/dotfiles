import rich

from xonsh.built_ins import XSH
from xonsh.events import events

from prompt_toolkit.keys import Keys

import logging
from wes_logging import ensure_logger_is_setup, get_wes_logger

log = get_wes_logger("learn")
log.setLevel(logging.INFO)  # only failures (effectively shuts up the logger)

def dump_keymaps():
    return XSH.shell.shell.prompter.app.key_bindings.bindings

def dump_events():
    rich.print(events)

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

@events.on_command_not_found
def wes_command_not_found(cmd, **kwargs):
    rich.print(f"[red]Command not found...[/]\n    {cmd=}\n")
    if kwargs:
        rich.print(f"    {kwargs=}")
    # return {"cmd": ["echo","do", "something", "else" ...] + cmd, "env": {"FOO": "BAR"}}


# @events.on_precommand
@events.on_transform_command
def wes_colorful_output(cmd: str, **kwargs):
    # print(f"precommand: {cmd=}, {type(cmd)=}, {kwargs=}")
    #
    # TODO parse the command?
    # log.info(f"{cmd=}")
    cmd = cmd.strip()  # strip trailing \n on submit
    if cmd.strip().startswith("env"):
        if not "| bat -l env" in cmd:
            return f"{cmd} | bat -l env"
    if cmd.startswith("hf datasets info"):
        if not "| bat -l json" in cmd:
        # pipe to bat for coloring
        # hf datasets info roneneldan/TinyStories
            return f"{cmd} | bat -l json"
    # IIAC return nothing is preferred for no change?

# @events.on_pre_cmdloop
# def _event_show_tip(**kw):
#     import random
#     tips = ["Use Tab for completion", "Try 'xonfig' to configure xonsh"]
#     print("Tip:", random.choice(tips))
