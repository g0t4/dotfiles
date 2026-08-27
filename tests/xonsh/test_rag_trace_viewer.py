import json
import sys
from pathlib import Path

from rich.console import Console


ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))

from wes_rag_trace_viewer import main, newest_trace, project_trace  # noqa: E402


def trace_payload(query: str) -> dict:
    return {
        "source": "telescope",
        "duration_ms": 554,
        "request_body": {"query": query, "instruct": "Find related code"},
        "response": {
            "result": {
                "matches": [
                    {
                        "file": "/repo/generate_git_abbreviations.py",
                        "start_line_base0": 80,
                        "end_line_base0": 110,
                        "signature": "def generate() -> str:",
                        "text": "def generate() -> str:\n    pass",
                        "embed_score": 0.506,
                        "embed_rank": 44,
                        "rerank_score": 0.988,
                        "rerank_rank": 0,
                        "type": "ts",
                    }
                ]
            }
        },
    }


def test_newest_trace_and_rich_render_use_jq_projection(tmp_path):
    trace_dir = tmp_path / "ask-openai/rag/telescope"
    trace_dir.mkdir(parents=True)
    trace_path = trace_dir / "123-trace.json"
    trace_path.write_text(json.dumps(trace_payload("where are wes_git_abbrev")))

    assert newest_trace(tmp_path) == trace_path
    projected = project_trace(trace_path)
    assert projected["matches"][0]["start_line"] == 81

    console = Console(record=True, width=180)
    assert main([], state_dir=tmp_path, console=console) == 0
    rendered = console.export_text()
    assert "where are wes_git_abbrev" in rendered
    assert "98.8%  #1" in rendered
    assert "50.6%  #45" in rendered
    assert "generate_git_abbreviations.py:81-111" in rendered
