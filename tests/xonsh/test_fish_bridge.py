import test_setup # load first
from wes_fish_bridge import fish_function_capture_stdout

class Tests_Integration_FishBridge:
    """
    These are functions that return values that are sensitive to
    - to ANSI Escape Sequences like cursor type from fish vi mode.
    - iTerm2's shell integration that uses OSC to transmit workdir + user variables

    Think of these as integration tests, moreso than unit tests.
    """

    def test_repo_root(self):
        assert fish_function_capture_stdout("_repo_root") == "/Users/wesdemos/repos/github/g0t4/dotfiles"

    def test_git_current_branch(self):
        assert fish_function_capture_stdout("git_current_branch") == "master"

    def test_abbr_function_gdlcX_with_argument(self):
        assert fish_function_capture_stdout("gdlcX", "gdlc2") == "git log --patch HEAD~2..HEAD~1"


def test_captured_alias_uses_text_input_and_output(monkeypatch):
    import io
    import wes_fish_bridge as bridge

    calls = []

    def capture(name, *args, **kwargs):
        calls.append((name, args, kwargs))
        return 'styled source'

    monkeypatch.setattr(bridge, 'fish_function_capture_stdout', capture)
    output = io.StringIO()
    assert bridge.captured_fish_alias('helper')(
        ['two words'], stdin=io.StringIO('input\n'), stdout=output,
    ) == 0
    assert calls == [('helper', ('two words',), {'input_text': 'input\n'})]
    assert output.getvalue() == 'styled source\n'


def test_captured_alias_reports_fish_failure(monkeypatch):
    import io
    import wes_fish_bridge as bridge

    def capture(*args, **kwargs):
        raise bridge.FishFunctionError('helper exited 3')

    monkeypatch.setattr(bridge, 'fish_function_capture_stdout', capture)
    errors = io.StringIO()
    assert bridge.captured_fish_alias('helper')([], stderr=errors) == 1
    assert errors.getvalue() == 'helper exited 3\n'
