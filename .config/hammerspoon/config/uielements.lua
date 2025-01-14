--
-- *** INSPECT ELEMENT HELPERS ***

local skipVerboseAttrs = { AXValue = true } -- PRN truncate long values instead? could pass max length here
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "A", function()
    -- TODO applescript genereator based on path (IIAC I can use role desc to build applescript?)
    local coords = hs.mouse.absolutePosition()
    local elementAt = hs.axuielement.systemElementAtPosition(coords.x, coords.y)
    DumpAXPath(elementAt, true)
    DumpAXAttributes(elementAt, skipVerboseAttrs)
    print(BuildAppleScriptTo(elementAt))
end)

function BuildAppleScriptTo(toElement)
    local script = ""
    -- REMEMBER toElement is last item in :path() list/table so dont need special handling for it outside of list
    -- TODO stop at len -1 so we can finish it and can check parent for dup types and need to constraint it or mark where dups are issue
    for _, elem in pairs(toElement:path()) do
        DumpAXAttributes(elem, skipVerboseAttrs)
        local role = GetValueOrEmptyString(elem, "AXRole")
        local roleDescription = GetValueOrEmptyString(elem, "AXRoleDescription")
        local current = "first " .. roleDescription .. " of "
        if role == "AXApplication" then
            current = "first application process '" .. GetValueOrEmptyString(elem, "AXTitle") .. "'"
        end
        script = current .. script .. '\n'
        -- for k1, v1 in pairs(v) do
        --     print("  * ", k1, v1)
        -- end
    end
    local roleDescription = GetValueOrEmptyString(toElement, "AXRoleDescription")
    -- print("*" .. roleDescription)
    return "set foo to " .. script
end

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "I", function()
    -- INSPECT ELEMENT UNDER MOUSE POSITION
    local coords = hs.mouse.absolutePosition()
    print("coords: " .. hs.inspect(coords))
    -- TODO any variance in what element is selected? isn't there another method to find element? deepest or smth?
    local elementAt = hs.axuielement.systemElementAtPosition(coords.x, coords.y)
    DumpAXAttributes(elementAt)
    DumpAXPath(elementAt)
    DumpParentsAlternativeForPath(elementAt)
end)



-- *** HELPERS below for DUMPING info ***
function DumpParentsAlternativeForPath(element)
    -- ALTERNATIVE way to get path, IIAC this is how element:path() works?
    -- if not then just know this is available as an alternative
    local parent = element:attributeValue("AXParent")
    print("parent", hs.inspect(parent))
    if parent then
        if parent == element then
            print("parent == element")
            return
        end
        DumpParentsAlternativeForPath(parent)
    end
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

function GetDumpAXAttributes(element, skips)
    skips = skips or {}
    -- local roleDesc = GetValueOrEmptyString(element, "AXRoleDescription")
    local role = GetValueOrEmptyString(element, "AXRole")
    local title = GetValueOrEmptyString(element, "AXTitle")
    local result = '## ATTRIBUTES for - ' .. role .. ' - ' .. title .. '\n'
    for attrName, attrValue in pairs(element) do
        if not skips[attrName] then
            local nonStandard = not StandardAttributesSet[attrName]
            -- PRN denylist some attrs I don't care to see (unless pass a verbose flag or global DEBUG var of some sort?)
            if attrValue == nil then
                attrValue = 'nil'
            elseif type(attrValue) == 'string' then
                attrValue = '"' .. attrValue .. '"'
            else
                attrValue = tostring(attrValue)
            end
            if nonStandard then
                attrName = '** ' .. attrName
            end
            result = result .. "  " .. attrName .. ' = ' .. attrValue .. '\n'
            -- TODO descend attrs that are tables? conditionally? allowlist/denylist which ones?
            --   maybe just add flag to do this (and only for one level deep) -  i.e. AXFrame, AXPosition
        end
    end
    return result
end

-- *** non-standard attr identification ***
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
-- TODO AXSections (could this be useful in searching elements?
-- FYI I am using this detection really just to point them out to me so I can figure out what each one is and then exploit if useful
--   once I find something new, its ok to add to this list (so only new stick out)


function DumpAXAttributes(element, skips)
    print(GetDumpAXAttributes(element, skips))
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

function GetDumpElementLine(elem)
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
    -- TODO conditions to clear the description (dont show it)..
    --    i.e. AXApplication role, desc=application...
    --      AXWindow role, AXStandardWindow subrole... desc=standard window
    --    basically, condense what I show in path view (make it easily decipherable... IOTW always show role and if anything hide rightmost items (i.e. desc) when it doesn't tell me anything new... that is what I dislike about other inspectors, they are hard to decipher what matters (the one thing that doesn't stand out cuz everything else is duplicated)
    --
    -- TODO AXValue
    -- TODO AXValueDescription
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
    return current
end

function GetDumpPath(element, expanded)
    expanded = expanded or false
    -- OMG this is already way better than UI Element Inspector, and Accessibility Inspector
    local path = element:path()
    if #path > 0 then
        local result = '## PATH:\n'
        for _, elem in ipairs(path) do
            local current = GetDumpElementLine(elem)
            result = result .. current .. '\n'

            if expanded then
                local children = elem:attributeValue("AXChildren")
                for _, child in pairs(children) do
                    result = result .. "    " .. GetDumpElementLine(child) .. "\n"
                end
            end

            -- FYI can add one '-' to front of block comment start => ---[[ and then the block is back in play, and last
            --[[
            -- consider showing more attrs on 1 or a few lines below each path elem... that is another way to not have a bunch of fields in one line like other inspectors
            if expanded then
                -- iterate over its attrs
                -- TODO allow/deny list specific attrs to show/not show
                for k, v in pairs(elem) do
                    result = result .. "    " .. k .. "\n"
                end
            end
            --]]
        end
        return result
    else
        return "NO PATH - should not happen, even AXApplication (top level) has self as path"
    end
end

function DumpAXPath(element, expanded)
    print(GetDumpPath(element, expanded))
end

-- function DumpAxPathExpanded(element)
--     for k, v in pairs(element:path()) do
--         print(" * ", k)
--         for k1, v1 in pairs(v) do
--             print("  * ", k1, v1)
--         end
--     end
-- end
