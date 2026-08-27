"""Share Fish z history with Xonsh and offer semantic directory retrieval."""

import asyncio
import os
import sys
from pathlib import Path

from xonsh.dirstack import cd as _xonsh_cd


_wes_xonsh_lib = Path($XONSH_CONFIG_DIR) / "lib"
if str(_wes_xonsh_lib) not in sys.path:
    sys.path.insert(0, str(_wes_xonsh_lib))

from wes_fish_z import FishZ, FishZError
from wes_semantic_history import InferenceClient
from wes_semantic_z import SemanticZ


_wes_fish_z = FishZ()
_wes_semantic_z = SemanticZ(InferenceClient())
_wes_z_non_jumping_options = {
    "-c",
    "--clean",
    "-d",
    "--dir",
    "--directory",
    "-e",
    "--echo",
    "-h",
    "--help",
    "-l",
    "--list",
    "-p",
    "--purge",
    "-x",
    "--delete",
}


def _wes_z_alias(args, stdin=None, stdout=None, stderr=None, **_):
    output_stream = stdout or sys.stdout
    error_stream = stderr or sys.stderr

    if any(argument in _wes_z_non_jumping_options for argument in args):
        return _wes_fish_z.run(
            args,
            cwd=os.getcwd(),
            stdin=stdin,
            stdout=stdout,
            stderr=stderr,
        ).returncode

    try:
        destination = _wes_fish_z.resolve(args)
    except FishZError as error:
        print(f"z: {error}", file=error_stream)
        return 1

    cd_stdout, cd_stderr, return_code = _xonsh_cd([str(destination)])
    if cd_stdout:
        print(cd_stdout, end="", file=output_stream)
    if cd_stderr:
        print(cd_stderr, end="", file=error_stream)
    return return_code


aliases["z"] = _wes_z_alias


def _wes_zr_alias(args, stdout=None, stderr=None, **_):
    output_stream = stdout or sys.stdout
    error_stream = stderr or sys.stderr
    arguments = list(args)
    show_list = "--list" in arguments or "-l" in arguments
    use_frecency = "--no-frecency" not in arguments
    arguments = [
        value
        for value in arguments
        if value not in {"--list", "-l", "--frecency", "--no-frecency"}
    ]
    query = " ".join(arguments).strip()
    if not query:
        print(
            "usage: zr [--list] [--frecency|--no-frecency] DESCRIPTION",
            file=error_stream,
        )
        return 2
    try:
        entries = _wes_fish_z.entries()
        matches = asyncio.run(
            _wes_semantic_z.retrieve(query, entries, use_frecency=use_frecency)
        )
    except (FishZError, OSError, TimeoutError, ValueError) as error:
        print(f"zr: {error}", file=error_stream)
        return 1
    if not matches:
        print(f"zr: no directory matched: {query}", file=error_stream)
        return 1
    if show_list:
        for match in matches:
            print(
                f"{match.score:.3f}  semantic={match.semantic_rank:<2} "
                f"frecency={match.frecency_rank:<2}  {match.path}",
                file=output_stream,
            )
        return 0

    destination = matches[0].path
    if not destination.is_dir():
        print(f"zr: result is not a directory: {destination}", file=error_stream)
        return 1
    cd_stdout, cd_stderr, return_code = _xonsh_cd([str(destination)])
    if cd_stdout:
        print(cd_stdout, end="", file=output_stream)
    if cd_stderr:
        print(cd_stderr, end="", file=error_stream)
    return return_code


aliases["zr"] = _wes_zr_alias


@events.on_chdir
def _wes_z_record_directory(olddir, newdir, **_):
    _wes_fish_z.record(newdir)
