import os

import pytest
from xonsh.built_ins import XSH
from xonsh.main import setup


@pytest.fixture
def shell():
    setup(
        shell_type="none",
        env={
            **os.environ,
            "XONSH_HISTORY_BACKEND": "dummy",
            "UPDATE_OS_ENVIRON": False,
        },
        ctx={},
    )
    yield XSH
    current_env = dict(os.environ)
    XSH.unload()
    os.environ.clear()
    os.environ.update(current_env)


def pytest_addoption(parser):
    parser.addoption(
        "--clanker-live", action="store_true", help="Run model capability validation"
    )
    parser.addoption(
        "--clanker-model",
        action="append",
        default=[],
        help="Model name from capability_models.json (repeatable; default all)",
    )
    parser.addoption(
        "--clanker-traces",
        default=None,
        help="Directory for capability traces and answers",
    )


def pytest_generate_tests(metafunc):
    if "capability_target" not in metafunc.fixturenames:
        return
    import json
    from pathlib import Path

    targets = json.loads(Path(__file__).with_name("capability_models.json").read_text())
    selected = metafunc.config.getoption("--clanker-model")
    unknown = set(selected) - {target["name"] for target in targets}
    if unknown:
        raise pytest.UsageError(f"Unknown capability models: {sorted(unknown)}")
    targets = [
        target for target in targets if not selected or target["name"] in selected
    ]
    metafunc.parametrize(
        "capability_target", targets, ids=[target["name"] for target in targets]
    )
