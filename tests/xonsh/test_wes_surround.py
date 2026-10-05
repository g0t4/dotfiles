from pathlib import Path

import pytest


ROOT = Path(__file__).parents[2]
XONSH_LIB = ROOT / ".config/xonsh/lib"


@pytest.fixture
def surround(monkeypatch):
    monkeypatch.syspath_prepend(str(XONSH_LIB))
    import wes_surround

    return wes_surround


def test_normalize_pair_open_and_closing_delimiters(surround):
    assert surround.normalize_pair("(") == ("(", ")")
    assert surround.normalize_pair(")") == ("(", ")")
    assert surround.normalize_pair("[") == ("[", "]")
    assert surround.normalize_pair("{") == ("{", "}")
    assert surround.normalize_pair("<") == ("<", ">")


def test_normalize_pair_symmetric_delimiters(surround):
    assert surround.normalize_pair('"') == ('"', '"')
    assert surround.normalize_pair("'") == ("'", "'")
    assert surround.normalize_pair("`") == ("`", "`")


def test_normalize_pair_unknown_char_is_symmetric(surround):
    assert surround.normalize_pair("x") == ("x", "x")


def test_find_surround_basic_pair(surround):
    text = "(foo)"
    assert surround.find_surround(text, 2, "(") == (0, 4)


def test_find_surround_accepts_closing_delimiter(surround):
    text = "(foo)"
    assert surround.find_surround(text, 2, ")") == (0, 4)


def test_find_surround_innermost_nested_pair(surround):
    text = "(a (b) c)"
    assert surround.find_surround(text, 4, "(") == (3, 5)
    assert surround.find_surround(text, 1, "(") == (0, 8)


def test_find_surround_symmetric_quotes(surround):
    text = '"foo" "bar"'
    # Cursor inside the second quoted word.
    assert surround.find_surround(text, 7, '"') == (6, 10)


def test_find_surround_cursor_outside_pair_is_none(surround):
    assert surround.find_surround("(foo)", 0, "(") is None
    assert surround.find_surround("(foo)", 5, "(") is None


def test_find_surround_unbalanced_is_none(surround):
    assert surround.find_surround("(foo", 2, "(") is None
    assert surround.find_surround("", 0, "(") is None


def test_delete_surround_basic(surround):
    new_text, new_pos, changed = surround.delete_surround("(foo)", 2, "(")
    assert changed
    assert new_text == "foo"
    assert new_pos == 1


def test_delete_surround_paired_delimiters(surround):
    new_text, _new_pos, changed = surround.delete_surround("[foo]", 2, "[")
    assert changed
    assert new_text == "foo"


def test_delete_surround_nested_only_removes_innermost(surround):
    new_text, _new_pos, changed = surround.delete_surround("(a (b) c)", 4, "(")
    assert changed
    assert new_text == "(a b c)"


def test_delete_surround_no_pair_is_noop(surround):
    new_text, new_pos, changed = surround.delete_surround("foo", 1, "(")
    assert not changed
    assert new_text == "foo"
    assert new_pos == 1


def test_change_surround_basic(surround):
    new_text, _new_pos, changed = surround.change_surround("(foo)", 2, "(", '"')
    assert changed
    assert new_text == '"foo"'


def test_change_surround_paired_to_paired(surround):
    new_text, _new_pos, changed = surround.change_surround("[foo]", 2, "[", "{")
    assert changed
    assert new_text == "{foo}"


def test_change_surround_no_pair_is_noop(surround):
    new_text, new_pos, changed = surround.change_surround("foo", 1, "(", ")")
    assert not changed
    assert new_text == "foo"
    assert new_pos == 1


def test_wrap_region_paired(surround):
    assert surround.wrap_region("foo bar", 0, 3, "(") == "(foo) bar"


def test_wrap_region_symmetric(surround):
    assert surround.wrap_region("foo bar", 0, 3, '"') == '"foo" bar'


def test_wrap_word_small_word(surround):
    new_text, new_pos, changed = surround.wrap_word("echo hello", 6, '"')
    assert changed
    assert new_text == 'echo "hello"'
    assert new_pos == 7


def test_wrap_word_inside_word_expands_to_whole_word(surround):
    new_text, _new_pos, changed = surround.wrap_word("hello world", 2, "'")
    assert changed
    assert new_text == "'hello' world"


def test_wrap_word_on_whitespace_picks_next_word(surround):
    new_text, _new_pos, changed = surround.wrap_word("echo hello", 5, '"')
    assert changed
    assert new_text == 'echo "hello"'


def test_wrap_word_big_word_includes_punctuation(surround):
    new_text, _new_pos, changed = surround.wrap_word("foo.bar", 1, '"', big=True)
    assert changed
    assert new_text == '"foo.bar"'


def test_wrap_word_big_word_excludes_punctuation_when_small(surround):
    new_text, _new_pos, changed = surround.wrap_word("foo.bar", 1, '"', big=False)
    assert changed
    assert new_text == '"foo".bar'


def test_wrap_word_no_word_is_noop(surround):
    new_text, new_pos, changed = surround.wrap_word("   ", 0, '"')
    assert not changed
    assert new_text == "   "
    assert new_pos == 0


def test_wrap_to_end(surround):
    new_text, new_pos, changed = surround.wrap_to_end("git add foo", 8, '"')
    assert changed
    assert new_text == 'git add "foo"'
    assert new_pos == 9
