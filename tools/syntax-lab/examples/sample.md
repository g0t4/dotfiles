# Markdown that feels like the code

Ordinary prose stays neutral. Headings use our rich purple, while
**important phrases** get amber and *gentle emphasis* gets teal.
There is no bold or italic terminal font styling.

## Links, code, and things to do

Read [the project notes](https://example.com/notes) or use `bat -pl md`.
The label stands out; the URL stays readable without dominating the paragraph.

- [x] Keep Python and Lua colors consistent
- [ ] Try this on a long README
- A normal list item with **emphasis** and `inline_code()`

1. Read the structure.
2. Then read the details.

> A quote gets a gentle teal lift, without fading into the background.

### Python keeps its own colors inside a fence

```python
def greeting(name: str) -> str:
    # Same comments, keywords, strings, and escapes as a Python file.
    return f"hello {name}\n"
```

### Lua feels familiar too

```lua
local function greeting(name)
    return "hello " .. name .. "\n"
end
```

## Tables and references

| Role | Color | Feeling |
| --- | --- | --- |
| Headings | Purple | Distinct, soft |
| Inline code | Teal | Easy to pick out |
| Prose | Neutral | Comfortable |

See [the baseline][theme]. ~~An old idea~~ can recede gently.

[theme]: ../palette.json

Another heading style
---------------------

Plain text, punctuation, and paths: ./some_file.py, a_b_c, 50%, a * b.
