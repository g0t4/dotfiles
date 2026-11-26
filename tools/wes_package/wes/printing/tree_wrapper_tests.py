# test case for TreeWrapper.add
import json
import pytest
from io import StringIO
from rich.console import Console

from tools.chat_viewer.tree_wrapper import TreeWrapper

def test_create_tree_without_label_nor_parent():
    tree = TreeWrapper()
    assert tree.label == ""
    assert tree.parent == None

def test_sections_from_json_keys():
    tree = TreeWrapper()
    tree.list_json_key_value_pairs('{"section1": 1, "section2": 2}')
    assert len(tree.children) == 2
    child1 = tree.children[0]
    assert child1
    assert "section1" in child1.label
    child2 = tree.children[1]
    assert child2
    assert "section2" in child2.label

def get_recorded_from_json(json_str):
    tree = TreeWrapper()
    tree.list_json_key_value_pairs(json_str)
    return record_plaintext(tree)

def record_plaintext(tree: TreeWrapper) -> str:
    console = Console(record=True, width=120, force_terminal=False)
    console.print(tree)
    # `export_text` returns a `str` with markup stripped.
    return console.export_text()

def get_recorded(what):
    tree = TreeWrapper()
    tree.list_key_value_pairs(what)
    return record_plaintext(tree)

class Test_TreeWrapper__list_key_value_pairs:

    def test_python_dict(self):
        # * scalar types for values in items (key/value pairs)
        assert get_recorded({"key": "string_value"}) == "\n    key: string_value\n"
        assert get_recorded({"key": 1}) == "\n    key: 1\n"
        assert get_recorded({"key": True}) == "\n    key: True\n"
        assert get_recorded({"key": 1.1}) == "\n    key: 1.1\n"
        assert get_recorded({"key": None}) == "\n    key: None\n"

    def test_python_list(self):
        assert get_recorded({"key": ["item1", "item2"]}) == "\n    key:\n        ['item1', 'item2']\n"
        assert get_recorded({"key": [1, 1.1]}) == "\n    key:\n        [1, 1.1]\n"
        assert get_recorded({"key": [None]}) == "\n    key:\n        [None]\n"
        assert get_recorded({"key": [{"foo": "bar"}]}) == "\n    key:\n        [{'foo': 'bar'}]\n"

    def test_json_dict_value(self):
        assert """key:\n        {'inner': 'value'}""" in get_recorded_from_json('{"key": {"inner": "value"}}')

    def test_primitive_values_do_not_fail(self) -> None:
        tree = TreeWrapper()
        tree.list_json_key_value_pairs('{"a": 1, "b": "text", "c": true}')

        recorded = record_plaintext(tree)

        expected_fragments = [
            # at least make sure no errors writing the values
            "a: 1",
            "b: text",
            "c: True",
        ]

        for fragment in expected_fragments:
            assert fragment in recorded, f"Missing fragment in recorded output: {fragment}"

def test_add_without_label_should_use_empty_string():
    tree = TreeWrapper()
    node = tree.add()
    assert node.label == ""
