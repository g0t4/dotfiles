## Lua Code Preferences

- use snake_case for functions and variables
- use PascalCase for classes
- use EmmyLua/LuaLS annotations to improve code completion
- use `luac` to check for syntax errors

Examples:
```lua
---@param names string[]
---@param checker fun(name: string): boolean
---@return table<string, integer>
function process_names(names, checker) end

---@class WindowController
---@field window hs.axuielement
---@field title? string
---@field size { w: number, h: number }
local WindowController = {}
```
