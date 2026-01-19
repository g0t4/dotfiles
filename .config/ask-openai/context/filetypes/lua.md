## Lua Code Preferences

Naming
- Use snake_case for functions and variables.
- Use PascalCase for classes.

Type Hints
- Prefer EmmyLua/LuaLS style annotations
- Always annotate when type inference would be ambiguous, or for public APIs.

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

