"""Scoped, nearest-parent .config.xsh files for interactive Xonsh sessions.

In a project's .config.xsh::

    from wes_local_config import local_abbr, local_function

    @local_function
    def project_name():
        return "my-project"

    local_abbr("serve", "uv run server")
"""

from __future__ import annotations

import inspect
from contextvars import ContextVar
from pathlib import Path
from re import Pattern
from typing import Any, Callable, TypeVar

from wes_abbreviations import Abbreviation, ExpansionCallback, ExpansionValue


_MISSING = object()
_Function = TypeVar("_Function", bound=Callable[..., Any])


class LocalConfigManager:
    def __init__(self, *, ctx, env, registry, execx):
        self.ctx = ctx
        self.env = env
        self.registry = registry
        self.execx = execx
        self.active_path = None
        self._loading_path = None
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

    def _register_function(self, function: _Function) -> _Function:
        self._set_scoped(self.ctx, function.__name__, function)
        return function

    def _register_abbr(
        self,
        trigger: str | Pattern[str],
        replacement: ExpansionValue | ExpansionCallback,
        *,
        _call_line: int,
        **options: Any,
    ) -> Abbreviation:
        options.setdefault("source_file", str(self._loading_path))
        options.setdefault("source_line", _call_line)
        abbreviation = self.registry.add(Abbreviation(trigger, replacement, **options))

        def undo():
            for index, current in enumerate(self.registry.abbreviations):
                if current is abbreviation:
                    del self.registry.abbreviations[index]
                    break

        self._undos.append(undo)
        return abbreviation

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

            local_ctx = {
                "__file__": str(path),
                "__name__": "__local_config__",
                "local_function": local_function,
                "local_env": local_env,
                "local_abbr": local_abbr,
            }
            self._loading_path = path
            token = _active_manager.set(self)
            try:
                self.execx(path.read_text(), "exec", local_ctx, filename=str(path))
            except BaseException:
                self.deactivate()
                raise
            finally:
                _active_manager.reset(token)
                self._loading_path = None
            self.active_path = path
        finally:
            self._updating = False


_active_manager: ContextVar[LocalConfigManager | None] = ContextVar(
    "wes_local_config_manager", default=None
)


def _manager() -> LocalConfigManager:
    manager = _active_manager.get()
    if manager is None:
        raise RuntimeError("local config helpers can only be called while loading .config.xsh")
    return manager


def local_function(function: _Function) -> _Function:
    """Expose a function at the Xonsh prompt until this config unloads."""
    return _manager()._register_function(function)


def local_env(name: str, value: Any) -> None:
    """Set an environment variable until this config unloads."""
    manager = _manager()
    manager._set_scoped(manager.env, name, value)


def local_abbr(
    trigger: str | Pattern[str],
    replacement: ExpansionValue | ExpansionCallback,
    **options: Any,
) -> Abbreviation:
    """Register an abbreviation until this config unloads."""
    caller = inspect.currentframe().f_back
    try:
        call_line = caller.f_lineno
    finally:
        del caller
    return _manager()._register_abbr(
        trigger, replacement, _call_line=call_line, **options
    )
