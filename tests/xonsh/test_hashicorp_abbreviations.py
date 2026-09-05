import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))
sys.path.insert(0, str(ROOT / "xonsh"))

from generate_hashicorp_abbreviations import TARGET, generate  # noqa: E402
from wes_abbreviations import AbbreviationContext, reset_registry  # noqa: E402
from wes_hashicorp_abbreviations import register_hashicorp_abbreviations  # noqa: E402


def context(token):
    return AbbreviationContext(
        buffer=token,
        cursor=len(token),
        token_start=0,
        token_end=len(token),
        token=token,
        command_path=(),
        command_position=True,
    )


def registry():
    result = reset_registry()
    register_hashicorp_abbreviations()
    return result


def test_generated_hashicorp_abbreviations_are_in_sync():
    assert TARGET.read_text() == generate()


def test_vagrant_and_packer_abbreviations_are_available():
    abbreviations = registry()

    assert len(abbreviations.abbreviations) == 54
    assert abbreviations.expand(context("v"))[0].text == "vagrant"
    assert abbreviations.expand(context("vuv"))[0].text == (
        "vagrant up --provider=virtualbox"
    )
    assert abbreviations.expand(context("vsnpo"))[0].text == "vagrant snapshot pop"
    assert abbreviations.expand(context("pab"))[0].text == "packer build ."


def test_hashicorp_rc_registers_with_the_live_abbreviation_registry():
    abbreviations = ROOT / ".config/xonsh/rc.d/abbreviations.xsh"
    hashicorp = ROOT / ".config/xonsh/rc.d/hashicorp.xsh"
    command = (
        f"source {abbreviations}; source {hashicorp}; "
        "matches = [entry for entry in wes_abbreviations.XONSH_ABBREVIATIONS.abbreviations "
        "if entry.trigger == 'v' and entry.replacement == 'vagrant']; "
        "assert matches"
    )
    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command], capture_output=True, text=True
    )

    assert completed.returncode == 0, completed.stderr
