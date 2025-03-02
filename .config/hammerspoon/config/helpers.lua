local inspect = require("hs.inspect")
local fun = require("fun")

local M = {}

function M.pasteText(text, app)
    -- TODO if need be, can I track the app that was active when triggering the ask-openai action... so I can make sure to pass it to type into it only... would allow me to switch apps (or more important, if some other app / window pops up... wouldn't steal typing focus)
    --     hs.eventtap.keyStrokes(text[, application])
    -- FYI no added delay here like keyStroke (interesting)
    hs.eventtap.keyStrokes(text, app) -- app param is optional
end

function M.typeText(text, delay)
    delay = delay or 10000

    for char in text:gmatch(".") do
        -- hs.eventtap.keyStroke({}, char, 0)
        hs.eventtap.keyStrokes(char)
        hs.timer.usleep(delay)
        -- 1k is like almost instant
        -- 5k looks like super fast typer
        -- 10k looks like fast typer
        -- 20k?
    end
end

function Dump(...)
    -- ... declares 0+ args
    --  {... } collects the args into a var, so this is actually the rest like operator
    print(inspect({ ... }))
end

function DumpWithMetatables(...)
    -- TODO is this useful, need to find an example where I find it helpful...
    -- added this in theory to be useful
    print(inspect({ ... }, { metatables = true }))
end

function M.get_function_source(func)
    -- hack to see function body...
    local info = debug.getinfo(func, "S")
    if not info then
        return nil, "Unable to retrieve debug info"
    end

    if info.what ~= "Lua" then
        return nil, "Not a Lua function"
    end

    local source_file = info.source:sub(2) -- Remove "@" prefix from file name
    local start_line = info.linedefined
    local end_line = info.lastlinedefined

    local lines = {}
    local file = io.open(source_file, "r")
    if not file then
        return nil, "Cannot open source file: " .. source_file
    end

    for i = 1, end_line do
        local line = file:read("*line")
        if i >= start_line and line then
            table.insert(lines, line)
        end
    end

    file:close()
    return table.concat(lines, "\n")
end

-- PRN setup a timing module? and pass a block of code to be timed?
function GetTime()
    return hs.timer.secondsSinceEpoch()
end

function GetElapsedTimeSince(start_time)
    return GetTime() - start_time
end

function GetElapsedTimeInMilliseconds(start_time)
    local elapsed_time_seconds = GetElapsedTimeSince(start_time)
    -- round to 1 decimal place
    return math.floor(elapsed_time_seconds * 10000 + 0.5) / 10
end

function GetElapsedTimeInNanoseconds(start_time)
    local elapsed_time_seconds = GetElapsedTimeSince(start_time)
    return math.floor(elapsed_time_seconds * 1000000000)
end

function StartProfiler()
    local ProFi = require("ProFi")
    ProFi:start()
end

function StopProfiler(path)
    print("StopProfiler", path)
    path = path or "profi.txt"
    local ProFi = require("ProFi")
    ProFi:stop()
    ProFi:writeReport(path)
end

-- *** my own underscore impl
-- define globally so I don't need to split out a module, or aggregate it into other helpers as a module
_ = {}

--- works on all tables, but does not guarantee order
--- I added this b/c underscore.lua has broken detection of array/map
---   i.e. hs.axuilement.observer.notifications is not an array, but it treats it as such and thus appears empty
--- if you want ipairs semantics, use imap (uses ipairs under the hood)
---@param t table
---@param fn function
---@return table
function _.map(t, fn)
    local result = {}
    for k, v in pairs(t) do
        result[k] = fn(v)
    end
    return result
end

--- returns array of keys (values are dropped)
---@param t table
---@return table<integer, string>
function _.keys(t)
    local result = {}
    _.each(t, function(key, _)
        table.insert(result, key)
    end)
    return result
end

--- returns array of values (keys are dropped)
---@param t table
---@return table<integer, any>
function _.values(t)
    local result = {}
    _.each(t, function(_, value)
        table.insert(result, value)
    end)
    return result
end

--- preserves order for arrays only (integer, consecutive keys) (uses ipairs)
---   [i]map => [i]pairs
---@param t table
---@param fn function
---@return table
function _.imap(t, fn)
    local result = {}
    for i, v in ipairs(t) do
        result[i] = fn(v)
    end
    return result
end

--- works on all tables, but does not guarantee order (uses pairs)
--- usage:
---
---   _.each(hs.axuielement.observer.notifications, function(key, value)
---       print(" " .. key .. " => " .. value)
---   end)
---
---   _.each({ foo = "bar", baz = "qux" }, function(key, _)
---       print(key)
---   end)
---
---@param t table
---@param fn fun(key: string|integer, value: any)
function _.each(t, fn)
    for k, v in pairs(t) do
        fn(k, v)
    end
end

--- preserves order for arrays only (integer, consecutive keys) (uses ipairs)
function _.ieach(t, fn)
    for i, v in ipairs(t) do
        fn(v, i)
    end
end

--- preserves order for arrays only (integer, consecutive keys) (uses ipairs)
function _.ieachKey(t, fn)
    for i, v in ipairs(t) do
        fn(v, i)
    end
end

-- *** helpers for fun.lua

function EnumTableValues(tbl)
    return fun.enumerate(tbl):map(function(key, value)
        return value
    end)
end

function TableLeftJoin(theTable, separator)
    -- FYI just to get a bit of practice using luafun library
    --  surprised to find it provides very few methods (i.e. no reverse)
    return EnumTableValues(theTable)
        :foldl(function(accum, current)
            if accum == "" then
                -- don't join nothing with first entry
                return current
            end
            return accum .. separator .. current
        end, "")
end

-- TODO use https://github.com/mirven/underscore.lua/blob/master/lib/underscore.lua?
function TableReverse(theTable)
    -- just for practice
    local reversed = {}
    for _, v in pairs(theTable) do
        table.insert(reversed, 1, v)
    end
    return reversed
end

function TableContains(theTable, value)
    for _, v in pairs(theTable) do
        if v == value then return true end
    end
    return false
end

-- chainable too, perhaps add more overloads with builder pattern of chaining (return tablej)
function table_prepend(theTable, value)
    table.insert(theTable, 1, value)
    return theTable
end

function resolveHomePath(path)
    if path:sub(1, 1) == "~" then
        return os.getenv("HOME") .. path:sub(2)
    end
    return path
end

function lowercaseFirstLetter(str)
    if str == nil then
        return nil
    end
    return str:sub(1, 1):lower() .. str:sub(2)
end

-- *** type helpers
function isUserData(value, name)
    local valueType = type(value)
    if valueType ~= "userdata" then
        return false
    end
    return value.__name == name
end

function isStyledText(value)
    return isUserData(value, "hs.styledtext")
end

function quote(str)
    if str == nil then
        return "nil"
    end
    return "'" .. tostring(str) .. "'"
end

return M
