"""Add call parentheses to Python completions without changing commands."""

from __future__ import annotations

import builtins
from functools import wraps
import inspect
import re
from typing import Any

from xonsh.built_ins import XSH
from xonsh.completers.tools import RichCompletion, contextual_completer


_PYTHON_NAME = re.compile(r"(?:@\.)?[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*")
_MISSING = object()


def _resolve_python_name(name: str, namespace: dict[str, Any]) -> Any:
    """Look up a name without evaluating code or invoking descriptors."""
    if name.startswith("@."):
        parts = name[2:].split(".")
        value = XSH.interface
    else:
        parts = name.split(".")
        value = namespace.get(parts[0], _MISSING)
        if value is _MISSING:
            value = vars(builtins).get(parts[0], _MISSING)
        parts = parts[1:]
    for part in parts:
        if value is _MISSING:
            break
        try:
            value = inspect.getattr_static(value, part)
        except AttributeError:
            return _MISSING
    if isinstance(value, (classmethod, staticmethod)):
        value = value.__func__
    return value


def _call_completion(candidate, context):
    python = context.python
    if python is None or python.ctx is None:
        return candidate
    if isinstance(candidate, RichCompletion) and candidate.provider not in (None, "python"):
        return candidate

    value = str(candidate)
    name = value.removesuffix("(")
    if not _PYTHON_NAME.fullmatch(name):
        return candidate

    target = _resolve_python_name(name, python.ctx)
    if target is _MISSING or not callable(target):
        return candidate

    if isinstance(candidate, RichCompletion):
        return candidate.replace(value=name + "()", display=name + "()", append_space=False)
    return RichCompletion(name + "()", display=name + "()")


def _decorate_result(result, context):
    if result is None:
        return None
    if isinstance(result, tuple):
        candidates, prefix_len = result
        return ({_call_completion(candidate, context) for candidate in candidates}, prefix_len)
    return (_call_completion(candidate, context) for candidate in result)


def wrap_python_call_completions(completer):
    """Preserve an existing contextual completer's ordering and metadata."""

    @wraps(completer)
    @contextual_completer
    def wrapped(context):
        return _decorate_result(completer(context), context)

    return wrapped
