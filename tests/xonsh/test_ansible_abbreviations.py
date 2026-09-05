import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))
sys.path.insert(0, str(ROOT / "xonsh"))

from generate_ansible_abbreviations import TARGET, generate  # noqa: E402
from wes_abbreviations import AbbreviationContext, reset_registry  # noqa: E402
import wes_abbreviations
from wes_ansible_abbreviations import (  # noqa: E402
    FISH_FUNCTIONS,
    register_ansible_abbreviations,
)


def context(token):
    return AbbreviationContext(
        buffer=token,
        cursor=len(token),
        token_start=0,
        token_end=len(token),
        token=token,
        command_position=True,
    )


def registry():
    registry = reset_registry()
    register_ansible_abbreviations()
    return registry


def test_generated_module_is_in_sync_with_ansibles_fish_source():
    assert TARGET.read_text() == generate()


def test_inventory_includes_every_abbreviation_and_function():
    entries = registry().abbreviations

    assert len(entries) == 61
    assert FISH_FUNCTIONS == (
        "_ansible-config_options_name_contains",
        "_ansible-config_option_details_contains",
    )


def test_playbook_inventory_and_cursor_abbreviations():
    abbreviations = registry()

    result, _ = abbreviations.expand(context("apcd"))
    assert result.text == "ansible-playbook --check --diff"

    result, _ = abbreviations.expand(context("ails"))
    assert result.text == "ansible-inventory --list --yaml"

    result, _ = abbreviations.expand(context("ails_generate_yaml_inventory"))
    assert result.text == "ansible-inventory --list --yaml -i foo,bar > inventory.yml"
    assert result.cursor == len("ansible-inventory --list --yaml -i foo,bar")


def test_ansible_rc_loads_with_abbreviations_and_bridged_functions():
    abbreviations = ROOT / ".config/xonsh/rc.d/abbreviations.xsh"
    ansibles = ROOT / ".config/xonsh/rc.d/ansibles.xsh"
    command = (
        f"source {abbreviations}; source {ansibles}; "
        "print(len(wes_abbreviations.XONSH_ABBREVIATIONS.abbreviations)); "
        "print('_ansible-config_options_name_contains' in aliases)"
    )
    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command], capture_output=True, text=True
    )

    assert completed.returncode == 0, completed.stderr
    assert completed.stdout.splitlines() == ["62", "True"]
