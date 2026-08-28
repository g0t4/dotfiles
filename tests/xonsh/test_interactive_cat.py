import io
import os
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).parents[2]
sys.path.insert(0, str(ROOT / ".config/xonsh/lib"))

from wes_interactive_cat import InteractiveCat  # noqa: E402


class Tty(io.StringIO):
    def isatty(self):
        return True


class Env(dict):
    def detype(self):
        return {
            key: os.pathsep.join(value) if key == "PATH" else str(value)
            for key, value in self.items()
        }


class Spec:
    def __init__(self, *, last=True, captured="hiddenobject", captured_stdout=object()):
        self.last_in_pipeline = last
        self.captured = captured
        self.captured_stdout = captured_stdout


def harness(tmp_path, monkeypatch):
    calls = []
    tools = tmp_path / "bin"
    tools.mkdir(parents=True)
    for name in ("cat", "bat", "eza", "file", "imgcat"):
        executable = tools / name
        executable.touch()
        executable.chmod(0o755)

    def run(argv, **kwargs):
        calls.append((argv, kwargs))
        stdout = "text/plain\n" if Path(argv[0]).name == "file" else ""
        return subprocess.CompletedProcess(argv, 0, stdout=stdout, stderr="")

    cat = InteractiveCat(env=Env(PATH=[str(tools)]), run=run)
    return cat, calls


def test_interactive_operands_dispatch_files_directories_and_images(
    tmp_path, monkeypatch
):
    cat, calls = harness(tmp_path, monkeypatch)
    text = tmp_path / "notes.txt"
    text.write_text("hello")
    image = tmp_path / "frame.png"
    image.write_bytes(b"png")
    directory = tmp_path / "folder"
    directory.mkdir()

    # Make only the named image report an image MIME type.
    original_run = cat._run

    def run(argv, **kwargs):
        completed = original_run(argv, **kwargs)
        if Path(argv[0]).name == "file":
            completed.stdout = (
                "image/png\n" if argv[-1] == str(image) else "text/plain\n"
            )
        return completed

    cat._run = run

    assert cat([str(text), str(directory), str(image)], stdin=Tty(), stdout=Tty()) == 0
    commands = [Path(argv[0]).name for argv, _ in calls]
    assert commands == ["file", "bat", "eza", "file", "imgcat"]
    assert calls[1][0][1:] == ["--color=always", "--", str(text)]


def test_bat_color_is_not_forced_when_output_is_piped(tmp_path, monkeypatch):
    cat, calls = harness(tmp_path, monkeypatch)
    text = tmp_path / "notes.txt"
    text.write_text("hello")

    assert cat([str(text)], stdin=Tty(), stdout=io.StringIO()) == 0
    assert calls[1][0][1:] == ["--", str(text)]


def test_xonsh_capture_model_distinguishes_terminal_pipeline_and_redirect(
    tmp_path, monkeypatch
):
    text = tmp_path / "notes.txt"
    text.write_text("hello")

    terminal_cat, terminal_calls = harness(tmp_path / "terminal", monkeypatch)
    assert terminal_cat([str(text)], stdin=Tty(), spec=Spec()) == 0
    assert terminal_calls[1][0][1] == "--color=always"

    pipeline_cat, pipeline_calls = harness(tmp_path / "pipeline", monkeypatch)
    assert pipeline_cat([str(text)], stdin=Tty(), spec=Spec(last=False)) == 0
    assert "--color=always" not in pipeline_calls[1][0]

    redirect_cat, redirect_calls = harness(tmp_path / "redirect", monkeypatch)
    assert redirect_cat([str(text)], stdin=Tty(), spec=Spec(captured_stdout=None)) == 0
    assert "--color=always" not in redirect_calls[1][0]


def test_no_arguments_lists_current_directory(tmp_path, monkeypatch):
    cat, calls = harness(tmp_path, monkeypatch)

    assert cat([], stdin=Tty()) == 0
    assert Path(calls[0][0][0]).name == "eza"
    assert calls[0][0][1:] == ["-al", "--", "."]


def test_piped_input_and_options_delegate_one_intact_cat_invocation(
    tmp_path, monkeypatch
):
    cat, calls = harness(tmp_path, monkeypatch)

    assert cat(["-n", "one", "two"], stdin=Tty()) == 0
    assert cat(["one", "two"], stdin=io.StringIO("piped")) == 0

    assert [call[0][1:] for call in calls] == [
        ["-n", "one", "two"],
        ["one", "two"],
    ]


def test_cat_override_is_installed_only_for_interactive_xonsh():
    abbreviations = ROOT / ".config/xonsh/rc.d/abbreviations.xsh"
    files_rc = ROOT / ".config/xonsh/rc.d/files-specific.xsh"
    env = os.environ.copy()
    env["XONSH_CONFIG_DIR"] = str(ROOT / ".config/xonsh")

    command = f"source {abbreviations}; source {files_rc}; print('cat' in aliases and callable(aliases['cat']))"
    noninteractive = subprocess.run(
        ["xonsh", "--no-rc", "-c", command], capture_output=True, text=True, env=env
    )
    interactive = subprocess.run(
        ["xonsh", "--no-rc", "-c", f"$XONSH_INTERACTIVE = True; {command}"],
        capture_output=True,
        text=True,
        env=env,
    )

    assert noninteractive.returncode == 0, noninteractive.stderr
    assert noninteractive.stdout.strip() == "False"
    assert interactive.returncode == 0, interactive.stderr
    assert interactive.stdout.strip() == "True"
