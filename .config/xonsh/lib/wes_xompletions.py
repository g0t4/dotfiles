"""Discover native Xonsh completers shipped by uv-managed tools."""

from __future__ import annotations

from collections.abc import Callable, Iterable, Mapping
from dataclasses import dataclass
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import sys
from types import ModuleType
from urllib.parse import unquote, urlparse


XOMPLETION_PRUNED_DIRECTORIES = {
    ".git",
    ".venv",
    "__pycache__",
    "node_modules",
    "venv",
}


def uv_tool_directory(env: Mapping[str, object] | None = None) -> Path:
    """Return uv's tool environment directory without spawning uv."""
    values = os.environ if env is None else env
    configured = values.get("UV_TOOL_DIR")
    if configured:
        return Path(str(configured)).expanduser()
    data_home = values.get("XDG_DATA_HOME")
    if data_home:
        return Path(str(data_home)).expanduser() / "uv" / "tools"
    return Path.home() / ".local" / "share" / "uv" / "tools"


def site_package_directories(venv: Path) -> list[Path]:
    """Find platform-independent site-packages directories in a venv."""
    candidates = [venv / "Lib" / "site-packages"]
    candidates.extend(sorted((venv / "lib").glob("python*/site-packages")))
    return [candidate for candidate in candidates if candidate.is_dir()]


def _editable_root(dist_info: Path) -> Path | None:
    direct_url = dist_info / "direct_url.json"
    if not direct_url.is_file():
        return None
    try:
        value = json.loads(direct_url.read_text(errors="replace"))
    except (json.JSONDecodeError, OSError):
        return None
    if not value.get("dir_info", {}).get("editable"):
        return None
    parsed = urlparse(value.get("url", ""))
    if parsed.scheme != "file":
        return None
    return Path(unquote(parsed.path)).resolve()


def source_roots_for_venv(venv: Path) -> list[Path]:
    """Return editable project roots plus installed site-packages roots."""
    roots: list[Path] = []
    for site_packages in site_package_directories(venv):
        for dist_info in sorted(site_packages.glob("*.dist-info")):
            editable = _editable_root(dist_info)
            if editable is not None:
                roots.append(editable)
        roots.append(site_packages)
    return _unique_paths(roots)


def source_roots_for_uv_tools(tool_directory: Path) -> list[Path]:
    """Return roots exposed by every uv tool environment."""
    if not tool_directory.is_dir():
        return []
    roots: list[Path] = []
    for venv in sorted(tool_directory.iterdir()):
        if venv.is_dir():
            roots.extend(source_roots_for_venv(venv))
    return _unique_paths(roots)


def _unique_paths(paths: Iterable[Path]) -> list[Path]:
    seen: set[Path] = set()
    result: list[Path] = []
    for path in paths:
        resolved = path.resolve()
        if resolved not in seen:
            seen.add(resolved)
            result.append(resolved)
    return result


def discover_xompletion_files(roots: Iterable[Path]) -> list[tuple[Path, Path]]:
    """Return ``(source root, xompletion __init__)`` pairs."""
    matches: list[tuple[Path, Path]] = []
    seen: set[Path] = set()
    for root in roots:
        root = root.resolve()
        tools = root / "tools"
        if not tools.is_dir():
            continue

        discovered: list[Path] = []
        for directory, child_directories, files in os.walk(tools):
            child_directories[:] = sorted(
                name
                for name in child_directories
                if name not in XOMPLETION_PRUNED_DIRECTORIES
            )
            path = Path(directory)
            if path.name != "xompletions" or "__init__.py" not in files:
                continue
            discovered.append(path / "__init__.py")
            child_directories.clear()

        for path in sorted(discovered):
            resolved = path.resolve()
            if resolved not in seen:
                seen.add(resolved)
                matches.append((root, resolved))
    return matches


def _package(name: str, path: Path) -> ModuleType:
    module = ModuleType(name)
    module.__package__ = name
    module.__path__ = [str(path)]
    module.__file__ = str(path / "__init__.py")
    return module


def _synthetic_prefix(path: Path, namespace: str) -> str:
    digest = hashlib.sha256(f"{namespace}\0{path}".encode()).hexdigest()[:16]
    return f"_wes_xompletion_{digest}"


@dataclass
class LoadedXompletions:
    completions: dict[str, Callable]
    module_prefixes: tuple[str, ...]

    def unload(self) -> None:
        for name in tuple(sys.modules):
            if any(
                name == prefix or name.startswith(f"{prefix}.")
                for prefix in self.module_prefixes
            ):
                sys.modules.pop(name, None)


def _command_names(module: ModuleType, default: str) -> tuple[str, ...]:
    declared = getattr(module, "COMMANDS", None)
    if declared is None:
        declared = (getattr(module, "COMMAND", default),)
    elif isinstance(declared, str):
        declared = (declared,)
    commands = tuple(str(command) for command in declared)
    if not commands or any(not command for command in commands):
        raise ValueError(f"invalid COMMANDS in {module.__file__}")
    return commands


def _load_xompletion(
    source_root: Path, path: Path, namespace: str
) -> tuple[ModuleType, str]:
    relative_package = path.parent.relative_to(source_root)
    package_parts = relative_package.parts
    prefix = _synthetic_prefix(path, namespace)
    sys.modules[prefix] = _package(prefix, source_root)

    for index in range(1, len(package_parts)):
        parts = package_parts[:index]
        name = ".".join((prefix, *parts))
        sys.modules[name] = _package(name, source_root.joinpath(*parts))

    module_name = ".".join((prefix, *package_parts))
    spec = importlib.util.spec_from_file_location(
        module_name,
        path,
        submodule_search_locations=[str(path.parent)],
    )
    if spec is None or spec.loader is None:
        raise ImportError(f"could not load xompletion module {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    try:
        spec.loader.exec_module(module)
    except BaseException:
        for name in tuple(sys.modules):
            if name == prefix or name.startswith(f"{prefix}."):
                sys.modules.pop(name, None)
        raise
    return module, prefix


def load_xompletions(
    roots: Iterable[Path], *, namespace: str = "standalone"
) -> LoadedXompletions:
    """Load completion functions without importing a repository's ``tools`` package."""
    completions: dict[str, Callable] = {}
    prefixes: list[str] = []
    try:
        for source_root, path in discover_xompletion_files(roots):
            module, prefix = _load_xompletion(source_root, path, namespace)
            prefixes.append(prefix)
            function = getattr(module, "xonsh_complete", None)
            if not callable(function):
                raise TypeError(f"{path} must define callable xonsh_complete(ctx)")
            default_command = path.parent.parent.name
            for command in _command_names(module, default_command):
                if command in completions:
                    raise ValueError(f"duplicate xompletion command {command!r}")
                completions[command] = function
    except BaseException:
        LoadedXompletions({}, tuple(prefixes)).unload()
        raise
    return LoadedXompletions(completions, tuple(prefixes))


class XompletionManager:
    """Maintain global and auto-venv-local native completion layers."""

    def __init__(self, *, tool_directory: Path | None = None):
        self.tool_directory = tool_directory or uv_tool_directory()
        self.global_scope = LoadedXompletions({}, ())
        self.local_scope = LoadedXompletions({}, ())
        self.global_loaded = False
        self.local_loaded = False
        self.local_venv: Path | None = None

    def load_global(self) -> None:
        self.global_scope.unload()
        roots = source_roots_for_uv_tools(self.tool_directory)
        self.global_scope = load_xompletions(roots, namespace="global")
        self.global_loaded = True

    def update_local(self, venv: str | os.PathLike[str] | None) -> None:
        resolved = Path(venv).resolve() if venv else None
        if resolved == self.local_venv:
            return
        self.local_scope.unload()
        self.local_scope = LoadedXompletions({}, ())
        self.local_loaded = False
        self.local_venv = resolved

    def _load_local(self) -> None:
        resolved = self.local_venv
        if resolved is not None:
            self.local_scope = load_xompletions(
                source_roots_for_venv(resolved), namespace=f"local:{resolved}"
            )
        self.local_loaded = True

    def _ensure_loaded(self) -> None:
        if not self.global_loaded:
            self.load_global()
        if not self.local_loaded:
            self._load_local()

    def get(self, command: str) -> Callable | None:
        self._ensure_loaded()
        return self.local_scope.completions.get(
            command
        ) or self.global_scope.completions.get(command)

    def complete(self, command: str, context):
        function = self.get(command)
        return function(context) if function is not None else None
