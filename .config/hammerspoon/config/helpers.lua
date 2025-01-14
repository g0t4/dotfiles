local inspect = require("hs.inspect")

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



return M
