import rich

from xonsh.built_ins import XSH
from xonsh.events import events
from xonsh.parsers.lexer import Lexer

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

def colorful_cat(tokens: list[str], cmd: str):
    if len(tokens) > 2:
        return # nothing for now if multi file
    # if it is a markdown file, pipe to glow to display it
    is_markdown = tokens[1].endswith('.md')
    if is_markdown:
        return f"{cmd} | glow"


@events.on_transform_command
def wes_colorful_output(cmd: str, **kwargs):
    if cmd is None:
        return
    cmd = cmd.strip()  # strip trailing \n on submit
    tokens = Lexer().split(cmd)
    if not any(tokens):
        return

    first_token = tokens[0]

    if first_token == "command":
        # when I use `command` I am expressly requesting to not make changes to what I am running (i.e. my overrides for cat, or even these coloring of output)
        return

    # PRN add commands from docker that I had setup with `grcify` that I removed in the fish configs too
    if first_token == "kubectl":
        if "-o yaml" in cmd:
            if not "| bat -l yaml" in cmd:
                return f"{cmd} | bat -l yaml"
        elif "-o json" in cmd:
            if not "| bat -l json" in cmd:
                return f"{cmd} | bat -l json"
        return # nothing == no changes

    if cmd.startswith("hf datasets info"):
        if not "| bat -l json" in cmd:
            return f"{cmd} | bat -l json"

    if first_token == "cat":
        return colorful_cat(tokens, cmd)


# @events.on_pre_cmdloop
# def _event_show_tip(**kw):
#     import random
#     tips = ["Use Tab for completion", "Try 'xonfig' to configure xonsh"]
#     print("Tip:", random.choice(tips))


# TODO later today you'll have time for this
# def test_subprocess_run():
#     import subprocess
#     subprocess.run(["fish", "-ic", "isatty stdin"]) # true
#     subprocess.run(["fish", "-ic", "isatty stdout"]) # true
#     echo foo | fish -ic "isatty stdin" # fails
#     fish -ic "isatty stdout" | cat # fails
# aliases['test_run'] = ... setup aliased function and see how stdin/stdout works in that model
