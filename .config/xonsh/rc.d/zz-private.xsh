"""Optionally load the private Xonsh configuration entrypoint."""

from pathlib import Path


_private_config_entrypoint = Path($WES_BOOTSTRAP) / "xonsh/config-private.xsh"
if _private_config_entrypoint.is_file():
    source @(str(_private_config_entrypoint))
