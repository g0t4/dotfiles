# lua code preferences

- Default to snake_case naming, i.e. for functions and variables.
- Use PascalCase for classes.

## type hints

Use EmmyLua/LuaLS style annotations, especially when type inference is ambiguous or not possible.

Examples:
---@param names string[]
---@param checker fun(PARAM: TYPE): RETURN_TYPE
---@return table<string, integer>

---@class WindowController
---@field window hs.axuielement
---@field title? string
---@field size { w: number, h: number }
