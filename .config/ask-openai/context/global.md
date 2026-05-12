## General Code Preferences

- Avoid ambiguity, for example:

```lua
-- 👎 if there's a bug in the regex, how would I know? I'd have to surmise from surrounding code 🤮
if line:match("^%s*$") then
    -- ...
end
```

```lua
-- 🙌 clear intent
local is_blank_line = line:match("^%s*$")
if is_blank_line then
    -- ...
end
```
