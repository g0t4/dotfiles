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

function DumpAXAttributes(obj)
    local roleDesc = obj:attributeValue("AXRoleDescription")
    local title = obj:attributeValue("AXTitle")
    if not title then title = "" end
    if not roleDesc then roleDesc = "" end
    print()
    print('## ATTRIBUTES for - ' .. roleDesc .. ' - ' .. title)
    for k, v in pairs(obj) do
        print(k, v)
    end
    print()
end

return M
