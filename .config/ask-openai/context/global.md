# General Code Preferences

- When rewriting code, leave unrelated code and unrelated comments as is.
- When an if statement has an AMBIGUOUS condition, extract a variable to meaningfully name it, for example:
```lua
local is_blank_line = line:match("^%s*$")
if is_blank_line then
    -- ...
end
```
