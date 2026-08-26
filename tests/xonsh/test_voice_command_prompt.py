import subprocess
from pathlib import Path


ROOT = Path(__file__).parents[2]


def test_voice_prompt_prominently_requires_xonsh_and_uses_english_context():
    autosuggest = ROOT / ".config/xonsh/rc.d/ai-autosuggest.xsh"
    command = (
        f"source {autosuggest}; "
        "from types import SimpleNamespace; "
        "buffer = SimpleNamespace(text='git ', history=None); "
        "_ai_autosuggester._recent_commands = lambda _: ['pwd']; "
        "context = _ai_autosuggester._voice_command_context("
        "buffer, 'list shell bindings', "
        "{'command': 'false', 'return_code': 1, 'output': ''}); "
        "assert 'specifically for Xonsh' in _AI_VOICE_COMMAND_SYSTEM_PROMPT; "
        "assert 'Do not substitute Bash, Zsh, Fish' in _AI_VOICE_COMMAND_SYSTEM_PROMPT; "
        "assert 'may span multiple lines' in _AI_VOICE_COMMAND_SYSTEM_PROMPT; "
        "assert 'Python-powered shell' in context; "
        "assert \"user's spoken request is \\\"list shell bindings\\\"\" in context; "
        "assert 'previous command and its bounded result' in context"
    )

    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
    )

    assert completed.returncode == 0, completed.stderr


def test_voice_command_cleaner_preserves_multiline_xonsh():
    autosuggest = ROOT / ".config/xonsh/rc.d/ai-autosuggest.xsh"
    command = (
        f"source {autosuggest}; "
        'value = "```xonsh\\nfor item in p`*.py`:\\n    print(item)\\n```"; '
        "assert _ai_autosuggester._clean_command(value) == "
        '"for item in p`*.py`:\\n    print(item)"'
    )

    completed = subprocess.run(
        ["xonsh", "--no-rc", "-c", command],
        capture_output=True,
        text=True,
    )

    assert completed.returncode == 0, completed.stderr
