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

def dump_keymaps2():
    # TODO which one shows everything?
    return XSH.shell.shell.prompter.app.key_processor._bindings._key_bindings.bindings

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
        return  # nothing for now if multi file
    # if it is a markdown file, pipe to glow to display it
    is_markdown = tokens[1].endswith('.md')
    if is_markdown:
        return f"{cmd} | glow"

# @events.on_precommand # cannot raise or otherwise stop execution, so likely use on_postcommand if you want to warn so it shows right after output (on_precommand puts it before and might be missed if lots of output)
@events.on_postcommand
def wes_habituate_new_commands_warnings(cmd: str, **kwargs):
    """
    sometimes I want to use a new command/subcommand to do some task... and I have a habit of using the old command/subcommand
    so, how about pester me with a warning when I do so! so I remember to do things different until I stop using the "old" way
    """
    if cmd is None:
        return

    # * avoid using `git checkout` entirely
    if "git checkout" in cmd:
        rich.print("\n\n[bold yellow]⚠️  Habit warning:[/] `git checkout` is deprecated in favor of `git switch`/`git restore`")
    # TODO add more warnings!


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
        return  # nothing == no changes

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


import signal

def sighup_history_flush():
    log.info("history flush")
    @.history.flush(at_exit=False)

try:
    # iTerm2 sends SIGHUP when you Close (Cmd+W) a pane... after the timeout duration (you can undo closing for X seconds)
    # currently, xonsh is not flushing history on SIGHUP, so I lose history when I use Close Window in iTerm2... I wanna keep using it and fix history, hence this stopgap
    # note I could resort to always using ctrl+d but I won't remember that until after I've lost recent history :) ... don't fight it
    # alternative: override Cmd+W and if it is xonsh then just immediately Ctrl+D the shell to exit which does flush history with JSON backend (at least)
    if $XONSH_VERSION > "0.25":
        print("you're using a new major version of xonsh, did they fix SIGHUP to flush history with JSON backend? if so drop this old stopgap")
    signal.signal(signalnum=signal.SIGHUP, handler=sighup_history_flush)
except (OSError, RuntimeError, ValueError):
    log.info("failed to register SIGHUP")
