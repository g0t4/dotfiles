import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))
sys.path.insert(0, str(ROOT / "xonsh"))

from wes_abbreviations import AbbreviationContext, reset_registry  # noqa: E402
import wes_abbreviations
from wes_ansible import register_wes_ansible

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
    register_wes_ansible()
    return registry


def test_inventory_includes_every_abbreviation_and_function():
    entries = registry().abbreviations

    assert any(entry.trigger == "apcd" for entry in entries)
    from xonsh.built_ins import XSH
    assert "_ansible-config_options_name_contains" in XSH.aliases
    assert "_ansible-config_option_details_contains" in XSH.aliases


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
    count, bridged = completed.stdout.splitlines()
    assert int(count) >= len(registry().abbreviations)
    assert bridged == "True"
