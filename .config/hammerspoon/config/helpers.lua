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

function DumpAXEverything(element)
    -- TODO header?
    local result = GetDumpAXAttributes(element)
    result = result .. "\n" .. GetDumpAXActions(element)
    -- PRN add parameterizedAttributes too
    print(result)
end

function GetValueOrDefault(element, attribute, default)
    local value = element:attributeValue(attribute)
    if value then
        return value
    else
        return default
    end
end

function GetValueOrEmptyString(element, attribute)
    local value = element:attributeValue(attribute)
    if value then
        return value
    else
        return ""
    end
end

function GetDumpAXAttributes(element)
    -- local roleDesc = GetValueOrEmptyString(element, "AXRoleDescription")
    local role = GetValueOrEmptyString(element, "AXRole")
    local title = GetValueOrEmptyString(element, "AXTitle")
    local result = '## ATTRIBUTES for - ' .. role .. ' - ' .. title .. '\n'
    for k, v in pairs(element) do
        local nonStandard = not StandardAttributesSet[k]
        -- PRN denylist some attrs I don't care to see (unless pass a verbose flag or global DEBUG var of some sort?)
        if v == nil then
            v = 'nil'
        elseif type(v) == 'string' then
            v = '"' .. v .. '"'
        else
            v = tostring(v)
        end
        if nonStandard then
            k = '** ' .. k
        end
        result = result .. "  " .. k .. ' = ' .. v .. '\n'
    end
    return result
end

StandardAttributesSet = {}
for _, value in pairs(hs.axuielement.attributes) do
    StandardAttributesSet[value] = true
end
-- add these as standard too:
StandardAttributesSet["AXFullScreen"] = true
StandardAttributesSet["AXFrame"] = true
StandardAttributesSet["AXPreferredLanguage"] = true
StandardAttributesSet["AXEnhancedUserInterface"] = true
-- AXFunctionRowTopLevelElements ?
-- AXChildrenInNavigationOrder ?
-- TODO look into nonstandard attrs:
--   TODO AXSections (could this be useful in searching elements?
-- FYI I am using this detection really just to point them out to me so I can figure out what each one is and then exploit if useful
--   once I find something new, its ok to add to this list (so only new stick out)


function DumpAXAttributes(element)
    print(GetDumpAXAttributes(element))
end

function GetDumpAXActions(element)
    local actions = element:actionNames()
    local result = ' ## NO ACTIONS'
    if #actions > 0 then
        result = '## ACTIONS: '
        for _, action in ipairs(actions) do
            result = result .. action .. ', '
        end
    end
    return result
end

function DumpAXActions(element)
    print(GetDumpAXActions(element))
end

function GetDumpPath(element)
    -- OMG this is already way better than UI Element Inspector, and Accessibility Inspector
    local path = element:path()
    if #path > 0 then
        local result = '## PATH:\n'
        for _, elem in ipairs(path) do
            local role = GetValueOrEmptyString(elem, "AXRole")
            local title = GetValueOrEmptyString(elem, "AXTitle")
            local subRole = GetValueOrEmptyString(elem, "AXSubrole")
            --
            local description = elem:attributeValue("AXDescription")
            local roleDescription = elem:attributeValue("AXRoleDescription")
            local useDescription = description or roleDescription
            if description and roleDescription then
                if description ~= roleDescription then
                    -- TODO find example to test
                    useDescription = roleDescription .. ' / ' .. description
                end
            end
            -- TODO AXValue
            -- TODO AXValueDescription
            --
            -- TODO WHAT ELSE (review attrs of sevearl apps you use... there can be non-standard attrs too... can't hurt to find those)
            --     TODO add a method to print non-standard attrs (not in the constants reference)
            --
            local identifier = elem:attributeValue("AXIdentifier") -- !!! UMM... this is news to me... can I search elements on this Identifier?!
            -- don't show identifier: Accessibility Inspector,
            -- Script Debugger only shows Identifier under Attributes list... so basically hidden... sheesh
            --
            local current = '  ' .. role
            if subRole ~= "" then
                current = current .. ' (' .. subRole .. ')'
            end
            current = current .. ' - ' .. title
            local details = ""
            if identifier then
                details = details .. ' id=' .. identifier
            end
            if useDescription then
                -- TODO I think I can exclude description (mostly mirrors Role/SubRole)
                details = details .. ' desc=' .. useDescription
            end
            if details ~= "" then
                current = current .. ' [' .. details .. ']'
            end
            result = result .. current .. '\n'
        end
        return result
    else
        return "NO PATH - should not happen, even AXApplication (top level) has self as path"
    end
end

function DumpAXPath(element)
    print(GetDumpPath(element))
end

return M
