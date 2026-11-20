"""Optionally load the private Xonsh configuration entrypoint."""

from pathlib import Path
import wes_env


_private_config_entrypoint = wes_env.bootstrap / "xonsh/config-private.xsh"
if _private_config_entrypoint.is_file():
    source @(str(_private_config_entrypoint))
