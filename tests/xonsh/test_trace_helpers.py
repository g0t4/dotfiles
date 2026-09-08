import json
import os
import re
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))

from wes_abbreviations import AbbreviationContext, reset_registry
from wes_trace_helpers import FISH_FUNCTIONS, register_trace_helpers


@pytest.fixture
def registry(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    registry = reset_registry()
    register_trace_helpers({}, ROOT)
    return registry


def expand(registry, token):
    context = AbbreviationContext(token, len(token), 0, len(token), token,
                                  command_position=True)
    result, _ = registry.expand(context)
    return result.text


def test_numbered_trace_file_sorting_and_nested_quoting(registry, tmp_path):
    (tmp_path / "b's $odd-trace.json").write_text("{}")
    (tmp_path / "a-trace.json").write_text("{}")
    assert "a-trace.json" in expand(registry, "t")
    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c",
         "import json; aliases['nvim'] = lambda args: print(json.dumps(args)); "
         + expand(registry, "t2a")], capture_output=True, text=True,
    )
    assert completed.returncode == 0, completed.stderr
    args = json.loads(completed.stdout)
    assert args[0] == "-c"
    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c",
         "import json; aliases['AskViewTrace'] = lambda args: print(json.dumps(args)); "
         + args[1]], capture_output=True, text=True,
    )
    assert completed.returncode == 0, completed.stderr
    assert json.loads(completed.stdout) == ["--all", "./b's $odd-trace.json"]
    assert expand(registry, "t99") == "nvim -c 'AskViewTrace'"


@pytest.mark.parametrize("token,expected", [
    ("tm99", {"content": "last"}),
    ("tc0", "echo voice"),
    ("msgc1", "last"),
    ("msgargs0", {"code": "echo voice"}),
])
def test_generated_jq_executes_in_xonsh(registry, tmp_path, token, expected):
    trace = {"request_body": {"messages": [
        {"tool_calls": [{"function": {"arguments": json.dumps({"code": "echo voice"})}}]},
        {"content": "last"},
    ]}}
    (tmp_path / "a space-trace.json").write_text(json.dumps(trace))
    completed = subprocess.run(["xonsh", "--no-rc", "-c", expand(registry, token)],
                               capture_output=True, text=True)
    assert completed.returncode == 0, completed.stderr
    actual = json.loads(completed.stdout) if isinstance(expected, dict) else completed.stdout.strip()
    assert actual == expected


def test_note_cursor_and_shortcuts(registry):
    assert expand(registry, "btx") == "browse_traces xonsh"
    context = AbbreviationContext("nat", 3, 0, 3, "nat", command_position=True)
    result, _ = registry.expand(context)
    assert result.text == "notes_about_trace ''"
    assert result.cursor == len("notes_about_trace '")


def test_source_function_inventory_is_accounted_for():
    sources = [ROOT / "fish/load_last_interactive_only/always/my_ai.fish",
               ROOT / "fish/load_last_interactive_only/rag_captures.fish"]
    names = {name for source in sources for name in re.findall(r"^function (\S+)", source.read_text(), re.M)}
    native = {"abbr_expand_trace_nth_file", "_abbr_trace_message", "_abbr_trace_command", "_abbr_msg_num"}
    assert names == set(FISH_FUNCTIONS) | native | {"mcp_server_semantic_grep"}


def test_rc_registers_and_wrapper_preserves_exact_stdin():
    rc = ROOT / ".config/xonsh/rc.d/trace-helpers.xsh"
    code = f"source {rc}; strip_trailing_newline"
    env = os.environ | {"XONSH_CONFIG_DIR": str(rc.parent.parent), "WES_DOTFILES": str(ROOT),
                        "PYTHONPATH": str(ROOT / '.config/xonsh/lib'), "TERM": "dumb"}
    env.pop("TERM_PROGRAM", None)
    completed = subprocess.run(["xonsh", "--no-rc", "-c", code], input="hello\n\n",
                               capture_output=True, text=True, env=env)
    assert completed.returncode == 0, completed.stderr
    assert completed.stdout == "hello\n"


def test_trace_collection_completion(tmp_path):
    (tmp_path / "xonsh").mkdir()
    (tmp_path / "agents").mkdir()
    rc = ROOT / ".config/xonsh/rc.d/trace-helpers.xsh"
    code = (
        f"source {rc}; "
        "from xonsh.parsers.completion_context import CompletionContextParser; "
        "parser = CompletionContextParser(); "
        "context = parser.parse('browse_traces x', len('browse_traces x')); "
        "assert {str(value) for value in _trace_helper_completer(context)} == {'xonsh'}"
    )
    env = os.environ | {"WES_DOTFILES": str(ROOT), "WES_ASK_CAPTURES": str(tmp_path),
                        "PYTHONPATH": str(ROOT / '.config/xonsh/lib')}
    completed = subprocess.run(["xonsh", "--no-rc", "-c", code],
                               capture_output=True, text=True, env=env)
    assert completed.returncode == 0, completed.stderr
