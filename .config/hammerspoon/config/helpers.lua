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

function TableReverse(theTable)
    -- just for practice
    local reversed = {}
    for _, v in pairs(theTable) do
        table.insert(reversed, 1, v)
    end
    return reversed
end

-- chainable too, perhaps add more overloads with builder pattern of chaining (return tablej)
---@diagnostic disable-next-line: lowercase-global
function table_prepend(theTable, value)
    table.insert(theTable, 1, value)
    return theTable
end

return M
