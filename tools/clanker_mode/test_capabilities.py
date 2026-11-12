"""Observable shell capabilities; prose format is deliberately not graded."""

import json
import time
from pathlib import Path
from uuid import uuid4

import pytest
from xonsh.history.json import JsonHistory

from clanker_mode import TRACE_DIR, run_agent

CASES = ["environment", "python_state", "history", "error_recovery"]
RUN_ID = str(time.time_ns())


@pytest.mark.live
@pytest.mark.parametrize("capability", CASES)
def test_shell_capability(shell, capability_target, capability, request, tmp_path):
    if not request.config.getoption("--clanker-live"):
        pytest.skip("Enable with --clanker-live")
    target = capability_target
    shell.env["CLANKER_BASE_URL"] = target["base_url"]
    shell.env["CLANKER_MODEL"] = target["model"]
    # Validation always uses disposable state, never the user's real history.
    shell.history = JsonHistory(filename=str(tmp_path / "history.json"), gc=False)
    hidden = uuid4().hex
    if capability == "environment":
        shell.env["CAPABILITY_HIDDEN"] = hidden
    elif capability in ("python_state", "error_recovery"):
        shell.ctx["capability_hidden"] = hidden
    else:
        shell.history.append({"inp": f"echo {hidden}\n", "rtn": 0, "ts": (1, 2)})
    prompts = {
        "environment": "Find and report the value of the CAPABILITY_HIDDEN environment variable in my current shell.",
        "python_state": "Read the existing Python variable capability_hidden, copy its value into a new Python variable capability_copy in my current shell, and report the value.",
        "history": "Look at my shell history and tell me the argument to my most recent echo command.",
        "error_recovery": "First execute print(capability_not_defined_yet) to see the error. Then recover by setting capability_not_defined_yet to the value of capability_hidden in my live shell, and report that value.",
    }
    root = Path(
        request.config.getoption("--clanker-traces")
        or TRACE_DIR / "validation" / RUN_ID
    )
    directory = root / target["name"] / capability / uuid4().hex[:8]
    request.node.user_properties.append(("trace_directory", str(directory)))
    answer = run_agent(prompts[capability], shell, trace_dir=directory, max_rounds=8)
    trace_path = next(directory.glob("*-trace.json"))
    trace = json.loads(trace_path.read_text())
    request.node.user_properties.extend(
        [("trace", str(trace_path)), ("answer", answer)]
    )
    print(f"\n{target['name']} / {capability}\n{answer}\nTrace: {trace_path}")
    # Require evidence from the tool, plus the discovered nonce somewhere in the
    # answer; Markdown, explanation, quoting and other prose are all acceptable.
    results = [m["content"] for m in trace["messages"] if m["role"] == "tool"]
    assert results, "Model did not use its shell tool"
    assert hidden in answer, "Answer did not report the discovered value"
    assert any(hidden in result for result in results), "No tool evidence for the value"
    if capability == "python_state":
        assert shell.ctx.get("capability_copy") == hidden, (
            "Change did not persist in shell"
        )
    if capability == "error_recovery":
        assert any("NameError" in result for result in results), (
            "Did not exercise requested failure"
        )
        assert shell.ctx.get("capability_not_defined_yet") == hidden, (
            "Did not recover in live shell"
        )


@pytest.mark.live
def test_commandline_suggestion(shell, capability_target, request):
    if not request.config.getoption("--clanker-live"):
        pytest.skip("Enable with --clanker-live")
    from clanker_mode import make_shell_tool

    target = capability_target
    shell.env["CLANKER_BASE_URL"] = target["base_url"]
    shell.env["CLANKER_MODEL"] = target["model"]
    hidden = uuid4().hex
    root = Path(
        request.config.getoption("--clanker-traces")
        or TRACE_DIR / "validation" / RUN_ID
    )
    directory = root / target["name"] / "commandline" / uuid4().hex[:8]
    request.node.user_properties.append(("trace_directory", str(directory)))
    answer = run_agent(
        f'Help me prepare a Python command that assigns True to capability_command_ran and prints "{hidden}". Put the command on my next command line so I can review and edit it. Do not run it.',
        shell,
        trace_dir=directory,
        max_rounds=8,
    )
    trace_path = next(directory.glob("*-trace.json"))
    request.node.user_properties.extend(
        [("trace", str(trace_path)), ("answer", answer)]
    )
    print(f"\n{target['name']} / commandline\n{answer}\nTrace: {trace_path}")
    queued = shell.env.get("XONSH_PROMPT_NEXT_CMD", "")
    assert queued, "No command queued for the next editable prompt"
    assert "capability_command_ran" not in shell.ctx, (
        "Model executed the suggestion prematurely"
    )
    trace = json.loads(trace_path.read_text())
    calls = [
        call for message in trace["messages"] for call in message.get("tool_calls", [])
    ]
    assert any(
        "replace_commandline" in call["function"]["arguments"] for call in calls
    ), "Model bypassed the advertised helper"
    # After checking that the model left it unexecuted, simulate the user accepting
    # the suggestion. Verify behavior rather than requiring an exact code string.
    output = make_shell_tool(shell).invoke({"code": queued.replace("<cursor>", "")})
    assert hidden in output
    assert shell.ctx.get("capability_command_ran") is True
