"""Optionally load the private Xonsh configuration entrypoint."""

from wes_timing import Timer

with Timer("00-private.xsh"):
    from pathlib import Path
    import wes_env


    _private_config_entrypoint = wes_env.bootstrap / "xonsh/config-private.py"
    if _private_config_entrypoint.is_file():
        source @(str(_private_config_entrypoint))
