"""Clipboard helpers ported from pbcopy-specific.fish."""

import os
import platform
import shlex
import shutil
import subprocess
import sys


def _clipboard_copy(data):
    """Copy text using native macOS tools or the best available remote/Linux tool."""
    if platform.system() == "Darwin" and shutil.which("pbcopy"):
        command = ["pbcopy"]
    elif ${...}.get("SSH_CLIENT") and shutil.which("osc"):
        command = ["osc", "copy"]
    elif ${...}.get("SSH_CLIENT") and shutil.which("osc-copy"):
        command = ["osc-copy"]
    elif shutil.which("wl-copy"):
        command = ["wl-copy"]
    elif shutil.which("xclip"):
        command = ["xclip", "-selection", "clipboard"]
    elif shutil.which("xsel"):
        command = ["xsel", "--clipboard", "--input"]
    else:
        print("pbcopy: no clipboard command found", file=sys.stderr)
        return 1

    return subprocess.run(command, input=data, text=True).returncode


def _clipboard_paste():
    if platform.system() == "Darwin" and shutil.which("pbpaste"):
        command = ["pbpaste"]
    elif ${...}.get("SSH_CLIENT") and shutil.which("osc"):
        command = ["osc", "paste"]
    elif shutil.which("wl-paste"):
        command = ["wl-paste", "--no-newline"]
    elif shutil.which("xclip"):
        command = ["xclip", "-selection", "clipboard", "-out"]
    elif shutil.which("xsel"):
        command = ["xsel", "--clipboard", "--output"]
    else:
        print("pbpaste: no clipboard command found", file=sys.stderr)
        return None

    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode:
        if result.stderr:
            print(result.stderr, end="", file=sys.stderr)
        return None
    return result.stdout

# prompt_toolkit uses pyperclip, so just replace its copy/paste mechanism with mine (works in my initial testing)
import pyperclip
pyperclip.copy = _clipboard_copy
pyperclip.paste = _clipboard_paste

def _cppath_value(args):
    if len(args) > 1:
        raise ValueError("cppath accepts zero or one path")

    # abspath normalizes . and .. but, unlike realpath, does not follow symlinks.
    path = os.path.abspath(os.path.expanduser(args[0])) if args else os.getcwd()
    home = os.path.expanduser("~")
    if path.startswith(home + os.sep):
        path = "~" + path[len(home):]

    if " " in path:
        if path.startswith("~/"):
            path = "~/" + shlex.quote(path[2:])
        else:
            path = shlex.quote(path)
    return path


def _cppath_alias(args, **_):
    try:
        value = _cppath_value(args)
    except ValueError as error:
        print(f"cppath: {error}", file=sys.stderr)
        return 1
    return _clipboard_copy(value)


def _pbcopy_alias(args, stdin=None, **_):
    if args:
        print("pbcopy: arguments are not supported", file=sys.stderr)
        return 1
    return _clipboard_copy(stdin.read() if stdin is not None else "")


def _pbpaste_alias(args, stdout=None, **_):
    if args:
        print("pbpaste: arguments are not supported", file=sys.stderr)
        return 1
    value = _clipboard_paste()
    if value is None:
        return 1
    print(value, end="", file=stdout or sys.stdout)
    return 0


def _clipboard_filter(command, stdout=None):
    value = _clipboard_paste()
    if value is None:
        return 1
    return subprocess.run(command, input=value, text=True, stdout=stdout).returncode


def _pbj_alias(args, stdout=None, **_):
    return _clipboard_filter(["jq"] + args, stdout)


def _pbj_toolcall_args_alias(args, stdout=None, **_):
    return _clipboard_filter(
        ["jq", ".tool_calls[0].function.arguments", "-r"] + args, stdout
    )


def _pby_alias(args, stdout=None, **_):
    return _clipboard_filter(["yq"] + args, stdout)


def _pbwc_alias(args, stdout=None, **_):
    command = ["wordcount"] if shutil.which("wordcount") else ["wc", "-w"]
    return _clipboard_filter(command + args, stdout)


def _pbn_alias(args, stdout=None, **_):
    if args:
        print("pbn: arguments are not supported", file=sys.stderr)
        return 1
    value = _clipboard_paste()
    if value is None:
        return 1
    print(value.rstrip("\n"), file=stdout or sys.stdout)
    return 0


def _pbcommand_alias(args, stdout=None, stderr=None, **_):
    if not args:
        print("usage: pbcommand COMMAND [ARG ...]", file=stderr or sys.stderr)
        return 1

    heading = "$ " + shlex.join(args) + "\n"
    try:
        process = subprocess.Popen(
            args,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
    except OSError as error:
        print(f"pbcommand: {error}", file=stderr or sys.stderr)
        return 1

    chunks = [heading]
    terminal = stdout or sys.stdout
    print(heading, end="", file=terminal)
    for chunk in iter(process.stdout.readline, ""):
        chunks.append(chunk)
        print(chunk, end="", file=terminal)
    process.wait()
    _clipboard_copy("".join(chunks))
    return process.returncode


aliases["cppath"] = _cppath_alias
aliases["pwdcp"] = _cppath_alias
aliases["pb"] = _pbpaste_alias
aliases["pbj"] = _pbj_alias
aliases["pbj_toolcall_args"] = _pbj_toolcall_args_alias
aliases["pby"] = _pby_alias
aliases["pbwc"] = _pbwc_alias
aliases["pbn"] = _pbn_alias
aliases["pbcommand"] = _pbcommand_alias

# macOS already supplies these executables. On other platforms, present the
# same interface using OSC, Wayland, or X11 clipboard tools.
if platform.system() != "Darwin":
    aliases["pbcopy"] = _pbcopy_alias
    aliases["pbpaste"] = _pbpaste_alias


@events.on_ptk_create
def _wes_clipboard_keybindings(bindings, **_):
    # Escape+k and Alt+k produce the same prompt-toolkit key sequence.
    @bindings.add("escape", "k")
    def _copy_and_clear_buffer(event):
        text = event.current_buffer.text.rstrip("\n")
        _clipboard_copy(text)
        event.current_buffer.text = ""
