"""Dump Kubernetes resources grouped by scope, with Rich status output."""

from __future__ import annotations

import argparse
import re
import shlex
import subprocess
import sys

from rich.console import Console


def kgdump(args, stdin=None, stdout=None, stderr=None):
    parser = argparse.ArgumentParser(prog="kgdump")
    parser.add_argument("-t", "--type", help="filter resource types by regex")
    parser.add_argument("namespace", nargs="?")
    try:
        options = parser.parse_args(args)
        pattern = re.compile(options.type) if options.type is not None else None
    except SystemExit as error:
        return error.code
    except re.error as error:
        print(f"kgdump: invalid type regex: {error}", file=stderr or sys.stderr)
        return 2

    console = Console(file=stdout or sys.stdout, markup=False, highlight=False)
    namespace_args = ["-n", options.namespace] if options.namespace else ["-A"]
    scopes = [True] if options.namespace else [False, True]
    status = 0
    try:
        for namespaced in scopes:
            if namespaced:
                console.print()
                heading = f"NAMESPACED( {shlex.join(namespace_args)} ):"
            else:
                heading = "NOT NAMESPACED:"
            console.print(heading, style="red")
            discovery = subprocess.run(
                ["kubectl", "api-resources", "--verbs=list",
                 f"--namespaced={str(namespaced).lower()}", "-o", "name"],
                stdout=subprocess.PIPE, stderr=stderr, text=True,
            )
            if discovery.returncode:
                status = discovery.returncode
                continue
            types = [name for name in discovery.stdout.splitlines()
                     if name and (pattern is None or pattern.search(name))]
            if not types:
                console.print("  NO matching types found", style="bold bright_white")
                continue
            command = ["kubectl", "get", "--show-kind", "--ignore-not-found", ",".join(types)]
            if namespaced:
                command.extend(namespace_args)
            console.print("  " + shlex.join(command), style="bright_black")
            console.file.flush()
            result = subprocess.run(command, stdin=stdin, stdout=stdout, stderr=stderr)
            if result.returncode:
                status = result.returncode
    except OSError as error:
        print(f"kgdump: {error}", file=stderr or sys.stderr)
        return 1
    return status


def complete_kgdump(prefix, line, begidx, endidx, ctx):
    try:
        words = shlex.split(line[:begidx])
    except ValueError:
        return None
    if not words or words[0] != "kgdump":
        return None
    if words[-1] in ("-t", "--type"):
        return set()
    if prefix.startswith("-"):
        return {flag for flag in ("-t", "--type", "-h", "--help") if flag.startswith(prefix)}
    try:
        result = subprocess.run(
            ["kubectl", "get", "namespace", "-o", "custom-columns=:metadata.name", "--no-headers"],
            capture_output=True, text=True,
        )
    except OSError:
        return set()
    return {name for name in result.stdout.splitlines() if name.startswith(prefix)} if result.returncode == 0 else set()
