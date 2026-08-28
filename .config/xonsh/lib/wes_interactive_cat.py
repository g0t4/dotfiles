"""Interactive ``cat`` enhancements for files, directories, and images."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path


class InteractiveCat:
    """Keep cat semantics while making simple interactive operands richer."""

    def __init__(self, *, env, run=subprocess.run, which=shutil.which):
        self._env = env
        self._run = run
        self._which = which

    def _environment(self):
        return self._env.detype()

    def _path(self):
        return os.pathsep.join(str(entry) for entry in self._env.get("PATH", ()))

    def _command(self, *names):
        search_path = self._path()
        for name in names:
            if executable := self._which(name, path=search_path):
                return executable
        return None

    def _execute(self, argv, *, stdin=None, stdout=None, stderr=None, capture=False):
        kwargs = {"env": self._environment()}
        if capture:
            kwargs.update(capture_output=True, text=True)
        else:
            kwargs.update(
                stdin=stdin,
                stdout=stdout,
                stderr=stderr,
            )
        return self._run(argv, **kwargs)

    def _stock_cat(self, args, *, stdin=None, stdout=None, stderr=None):
        cat = self._command("cat") or "/bin/cat"
        return self._execute(
            [cat, *args], stdin=stdin, stdout=stdout, stderr=stderr
        ).returncode

    def _list_directory(self, path, *, stdin=None, stdout=None, stderr=None):
        executable = self._command("exa", "eza", "lsd", "ls") or "/bin/ls"
        return self._execute(
            [executable, "-al", "--", str(path)],
            stdin=stdin,
            stdout=stdout,
            stderr=stderr,
        ).returncode

    def _show_file(self, path, *, stdin=None, stdout=None, stderr=None):
        executable = self._command("bat", "batcat")
        if executable is None:
            return self._stock_cat(
                [str(path)], stdin=stdin, stdout=stdout, stderr=stderr
            )
        return self._execute(
            [executable, "--", str(path)],
            stdin=stdin,
            stdout=stdout,
            stderr=stderr,
        ).returncode

    def _is_image(self, path):
        file_command = self._command("file") or "/usr/bin/file"
        completed = self._execute(
            [file_command, "--mime-type", "--brief", "--", str(path)],
            capture=True,
        )
        return completed.returncode == 0 and completed.stdout.startswith("image/")

    def _show_image(self, path, *, stdin=None, stdout=None, stderr=None):
        imgcat = self._command("imgcat")
        if imgcat is None:
            print(
                f"cat: {path} is an image but imgcat is unavailable",
                file=stderr or sys.stderr,
            )
            return 1
        return self._execute(
            [imgcat, str(path)],
            stdin=stdin,
            stdout=stdout,
            stderr=stderr,
        ).returncode

    def __call__(self, args, stdin=None, stdout=None, stderr=None, **_):
        input_stream = stdin or sys.stdin
        if not input_stream.isatty() or any(arg.startswith("-") for arg in args):
            return self._stock_cat(args, stdin=stdin, stdout=stdout, stderr=stderr)

        paths = args or ["."]
        status = 0
        for raw_path in paths:
            path = Path(raw_path).expanduser()
            if path.is_file():
                current = (
                    self._show_image(path, stdin=stdin, stdout=stdout, stderr=stderr)
                    if self._is_image(path)
                    else self._show_file(
                        path, stdin=stdin, stdout=stdout, stderr=stderr
                    )
                )
            elif path.is_dir():
                current = self._list_directory(
                    path, stdin=stdin, stdout=stdout, stderr=stderr
                )
            else:
                current = self._stock_cat(
                    [raw_path], stdin=stdin, stdout=stdout, stderr=stderr
                )
            status = status or current
        return status
