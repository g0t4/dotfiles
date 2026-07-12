## Python Code Preferences
- use snake_case for functions and variables
- use PascalCase for classes
- add type hints that improve code completion
- prefer `list[]` over `List[]` to mimimize imports
- `py_compile` is a great way to check for syntax errors

### I like pytest

pytest has stellar failure diffs (introspection):
- projections just work (tuples, lists, sets, dicts, etc) especially for complex comparisons
- use `assert`
- just say no to `self.assert*`

```python
# 🥰 (complex compare by projecting a list of tuples)
expected = [("c1", Range(0, 6)), ("c3", Range(6, 9))]
assert [(c.id, c.range) for c in removed.clips()] == expected

# 🤮 (repetitive assertions)
clips = list(removed.clips())
assert clips[0].id == "c1"
assert clips[0].range == Range(0, 6)
assert clips[1].id == "c3"
assert clips[1].range == Range(6, 9)
```

