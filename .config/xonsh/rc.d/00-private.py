"""Optionally load the private Xonsh configuration entrypoint."""

from wes_timing import Timer

with Timer("00-private.xsh"):
    from pathlib import Path
    import wes_env

    _private_config_entrypoint = wes_env.bootstrap / "xonsh/config-private.py"
    if _private_config_entrypoint.is_file():
        import importlib
        spec = importlib.util.spec_from_file_location("_private_config", str(_private_config_entrypoint))
        _private_config_module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(_private_config_module)
