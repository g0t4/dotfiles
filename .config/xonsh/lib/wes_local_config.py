"""Scoped, nearest-parent .config.xsh files for interactive Xonsh sessions."""

from __future__ import annotations

import inspect
from pathlib import Path

from wes_abbreviations import Abbreviation


_MISSING = object()


class LocalConfigManager:
    def __init__(self, *, ctx, env, registry, execx):
        self.ctx = ctx
        self.env = env
        self.registry = registry
        self.execx = execx
        self.active_path = None
        self._undos = []
        self._updating = False

    @staticmethod
    def find(start):
        directory = Path(start).resolve()
        for parent in (directory, *directory.parents):
            candidate = parent / ".config.xsh"
            if candidate.is_file():
                return candidate
        return None

    def deactivate(self):
        for undo in reversed(self._undos):
            undo()
        self._undos.clear()
        self.active_path = None

    def _set_scoped(self, mapping, key, value):
        previous = mapping.get(key, _MISSING)
        mapping[key] = value

        def undo():
            if previous is _MISSING:
                mapping.pop(key, None)
            else:
                mapping[key] = previous

        self._undos.append(undo)

    def update(self, directory):
        if self._updating:
            return
        path = self.find(directory)
        if path == self.active_path:
            return

        self._updating = True
        try:
            self.deactivate()
            if path is None:
                return

            def local_function(function):
                """Expose a function at the Xonsh prompt until this config unloads."""
                self._set_scoped(self.ctx, function.__name__, function)
                return function

            def local_env(name, value):
                """Set an environment variable until this config unloads."""
                self._set_scoped(self.env, name, value)

            def local_abbr(trigger, replacement, **options):
                """Register an abbreviation until this config unloads."""
                caller = inspect.currentframe().f_back
                try:
                    options.setdefault("source_file", str(path))
                    options.setdefault("source_line", caller.f_lineno)
                finally:
                    del caller
                abbreviation = self.registry.add(
                    Abbreviation(trigger, replacement, **options)
                )

                def undo():
                    for index, current in enumerate(self.registry.abbreviations):
                        if current is abbreviation:
                            del self.registry.abbreviations[index]
                            break

                self._undos.append(undo)
                return abbreviation

            local_ctx = {
                "__file__": str(path),
                "__name__": "__local_config__",
                "local_function": local_function,
                "local_env": local_env,
                "local_abbr": local_abbr,
            }
            try:
                self.execx(path.read_text(), "exec", local_ctx, filename=str(path))
            except BaseException:
                self.deactivate()
                raise
            self.active_path = path
        finally:
            self._updating = False
