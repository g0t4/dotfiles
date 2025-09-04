-- !!! DO NOT USE HAMMERSPOON APIS in here
-- setup any dependencies you ABSOLUTELY need
-- otherwise keep this code separate of your hs code
-- DO NOT use anything that cannot be loaded from package.path
-- ! ALSO! can run this with plenary unit test runner IF code executing is VANILLA JS code

function parse_time_to_seconds(time_string)
    ---@type number
    local total_seconds = 0
    -- time = "3:23.28"

    if time_string:find(":") then
        local parts = {}
        for part in time_string:gmatch("([^:]+)") do
            -- insert in reverse order so smallest is first (seconds => minutes => hours)
            table.insert(parts, 1, part)
        end

        local seconds = tonumber(parts[1]) or 0
        local minutes = tonumber(parts[2]) or 0
        total_seconds = minutes * 60 + seconds
        if #parts > 2 then
            local hours = tonumber(parts[3]) or 0
            total_seconds = total_seconds + hours * 3600
            if #parts > 3 then
                error("Cannot have time component bigger than hours  (h:m:s): " .. time_string)
            end
        end
    else
        total_seconds = tonumber(time_string) or 0
    end

    return total_seconds
end
