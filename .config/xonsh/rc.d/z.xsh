"""Share Fish's jethrokuan/z database and ranking behavior with Xonsh."""

import os
import sys
from pathlib import Path

from xonsh.dirstack import cd as _xonsh_cd


_wes_xonsh_lib = Path($XONSH_CONFIG_DIR) / "lib"
if str(_wes_xonsh_lib) not in sys.path:
    sys.path.insert(0, str(_wes_xonsh_lib))

from wes_fish_z import FishZ, FishZError


_wes_fish_z = FishZ()
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


@events.on_chdir
def _wes_z_record_directory(olddir, newdir, **_):
    _wes_fish_z.record(newdir)
