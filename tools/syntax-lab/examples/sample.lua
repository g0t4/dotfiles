-- Same palette, Lua lexer: comments stay visible.
local retries = 3
local delay = 0.25
local message = "hello\nworld"

local function collect_names(records)
    local names = {}
    for index, record in ipairs(records) do
        if record.active and record.name ~= nil then
            table.insert(names, string.format("%02d: %s", index, record.name))
        end
    end
    return names
end

local Worker = {}
function Worker:run(records)
    -- Long strings and method definitions exercise different tokens.
    local description = [[A multiline string
with no escape processing]]
    for attempt = 1, retries do
        print(message, description, delay * attempt)
    end
    return collect_names(records)
end

return Worker
