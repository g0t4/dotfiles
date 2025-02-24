local canvas = require("hs.canvas")
local alert = require("hs.alert")
local CachedElement = require("config.ax.caching")

local M = {}
M.last = {
    element = nil,
    tooltip = nil,
    callout = nil,
    text = nil,
    cycle = "AXChildren",
}
M.bindings = {}
local skips = {
    AXRole = true,
    AXChildren = true,
    AXChildrenInNavigationOrder = true,
    AXSelectedTextRanges = true,
    AXSelectedTextRange = true,
    AXSharedCharacterRange = true,
    AXVisibleCharacterRange = true,
    AXNumberOfCharacters = true,
    AXInsertionPointLineNumber = true,
    AXSharedTextUIElements = true,
    AXTextInputMarkedRange = true,
    AXTopLevelUIElement = true,
    AXWindow = true,
    AXParent = true,

    AXFrame = true,
    AXPosition = true,
    AXActivationPoint = true,
    AXSize = true,

    -- windows
    AXZoomButton = true,
    AXCloseButton = true,
    AXMinimizeButton = true,
    AXFullScreenButton = true,
    AXFullScreen = true,
    -- AXSections = true, -- very well useful on window level

    -- splitters
    AXNextContents = true,
    AXPreviousContents = true,
    AXSplitters = true,

    -- PRN outlines/tables(rows/columns)
    AXRows = true,
    AXColumns = true,
    AXVisibleRows = true,

    AXContents = true,
    AXVerticalScrollBar = true,

    -- AXApplication ... might be nice to constrain to only hide on AXApplication type?
    AXWindows = true,
}

local function onlyAlert(message)
    alert.closeAll()
    alert.show(message)
    print(message)
end

local function displayUserData(name, value)
    if value.__name == "hs.axuielement" then
        local role = value:attributeValue("AXRole")
        local title = value:attributeValue("AXTitle")
        local text = role
        if title then
            text = text .. " '" .. title .. "'"
        end
        local identifier = value:attributeValue("AXIdentifier")
        if identifier then
            text = text .. " " .. identifier
        end
        local description = value:attributeValue("AXDescription")
        if description then
            text = text .. " - " .. description
        end
        return text
    end
end
local function displayType(value)
    -- do return "" end -- uncomment to quickly turn off/on type display
    local valueType = type(value)
    if valueType == "boolean" then
        return "<bool>"
    end
    if valueType == "table" then
        -- tables are implicit with surrounding [ ]
        return ""
    end
    if valueType == "userdata" then
        valueType = value.__name
    end
    return "<" .. valueType .. ">"
end
local function displayTable(name, value)
    local text = ""
    for k, v in pairs(value) do
        if name == "AXSections" then
            -- FYI section entries have:
            --  SectionObject: AXScrollArea<hs.axuielement> - ** seems most important, the object itself :)
            --  SectionUniqueID: AXContent<string>
            --  SectionDescription: Toolbar<string>
            -- ! TODO try using this to find key parts of UI (i.e. inspector panel)
            text = text .. k .. ": " .. displayTable(k, v):gsub("\n", ", ")
        elseif type(v) == "userdata" then
            text = text .. k .. ": " .. displayUserData(k, v)
        else
            text = text .. k .. ": " .. tostring(v)
        end
        text = text .. displayType(v)
        text = text .. "\n"
    end
    return "[" .. text .. "]"
end
local function displayAttribute(name, value)
    if value == nil then return nil end
    if type(value) == "userdata" then
        return displayUserData(name, value)
    end
    if type(value) == "table" then
        return displayTable(name, value)
    end
    return tostring(value)
end

local function showTooltipForElement(element, frame)
    if not element then
        return
    end

    local specifierLua = BuildHammerspoonLuaTo(element)
    M.last.text = specifierLua

    local attributes = {}
    -- GOAL is to quickly see attrs that I can use to target elements
    --   hide the noise (nil, "", lists, attrs I dont care about)
    --   everything else => use html report
    for _, attrName in pairs(sortedAttributeNames(element)) do
        if skips[attrName] then goto continue end
        local attrValue = element:attributeValue(attrName)
        if attrValue == nil then goto continue end
        if attrName == "AXHelp" and attrValue == "" then goto continue end

        local value = displayAttribute(attrName, attrValue)
        -- only allow 50 chars max for text
        if not TableContains({ "AXSections" }, attrName) then
            if #value > 50 then
                value = value:sub(1, 50) .. "..."
            end
        end
        table.insert(attributes, attrName .. ": " .. value .. displayType(attrValue))

        ::continue::
    end
    local attributeDump = table.concat(attributes, "\n")

    local styledSpecifier = hs.styledtext.new(specifierLua, {
        font = {
            name = "SauceCodePro Nerd Font",
            size = 14
        },
        color = { white = 1 },
    })

    local styledAttributes = hs.styledtext.new(attributeDump, {
        font = {
            name = "SauceCodePro Nerd Font",
            size = 10
        },
        color = { white = 1 },
    })

    --- PRN move to a common definition file (helpers/hammerspoon.lua?)
    ---@type { w: number, h: number } | nil
    local specifierSize = hs.drawing.getTextDrawingSize(styledSpecifier)
    ---@type { w: number, h: number } | nil
    local attributeSize = hs.drawing.getTextDrawingSize(styledAttributes)
    -- BTW switching to styled text returns much more accurate dimensions (even if not monospaced font)

    -- add padding (don't subtract it from needed width/height)
    local padding = 10
    local tooltipWidth = math.max(specifierSize.w, attributeSize.w) + 2 * padding
    local tooltipHeight = specifierSize.h + attributeSize.h + 3 * padding

    local screenFrame = hs.screen.mainScreen():frame() -- Gets the current screen dimensions

    -- Initial positioning (slightly below the element)
    local x = frame.x
    local y = frame.y + frame.h + 5 -- Below the element

    -- Ensure tooltip does not go off the right edge
    if x + tooltipWidth > screenFrame.x + screenFrame.w then
        x = screenFrame.x + screenFrame.w - tooltipWidth - 10 -- Shift left
        -- IIUC the box is positioned to right of element left side so I don't think I need to worry about x being shifted left of screen
    end

    -- Ensure tooltip does not go off the bottom edge
    if y + tooltipHeight > screenFrame.y + screenFrame.h then
        -- if it's off the bottom, then move it above the element
        y = frame.y - tooltipHeight - 5 -- Move above element
        if y < screenFrame.y then
            -- if above is also off screen, then shift it down, INSIDE the frame
            --   means it stays on top btw... could put it inside on bottom too
            y = screenFrame.y + 10 -- Shift up
        end
    end

    local role = element:attributeValue("AXRole")
    local background = { white = 0, alpha = 1 }
    -- if role == "AXWindow" or role == "AXMenuBar" then
    if TableContains({ "AXMenuBar", "AXWindow" }, role) then
        -- dark green
        background = { hex = "#013220", alpha = 1 }
    elseif role == "AXApplication" then
        -- dark blue
        background = { hex = "#002040", alpha = 1 }
    end
    M.last.tooltip = canvas.new({ x = x, y = y, w = tooltipWidth, h = tooltipHeight })
        :appendElements({
            -- padding
            {
                -- background
                type = "rectangle",
                action = "fill",
                frame = { x = 0, y = 0, w = tooltipWidth, h = tooltipHeight },
                fillColor = background,
                roundedRectRadii = { xRadius = 8, yRadius = 8 }
            },
            {
                -- specifier
                type = "text",
                text = styledSpecifier,
                frame = { x = padding, y = padding, w = tooltipWidth - 2 * padding, h = specifierSize.h },
            },
            -- padding
            {
                -- attributes
                type = "text",
                text = styledAttributes,
                frame = { x = padding, y = 2 * padding + specifierSize.h, w = tooltipWidth - 2 * padding, h = attributeSize.h },
            },
            -- padding
        })
        :show()
end

local function removeHighlight()
    if not M.last.element then
        return
    end
    if M.last.tooltip then
        M.last.tooltip:delete()
    end
    if M.last.callout then
        M.last.callout:delete()
    end
    M.last.element = nil
    M.last.tooltip = nil
    M.last.callout = nil
end

local function highlightThisElement(element)
    removeHighlight()
    if not element then
        return
    end
    M.last.element = element
    local role = element:attributeValue("AXRole")

    local frame = element:attributeValue("AXFrame")
    if role == "AXApplication" then
        -- make synthetic frame to show app in upper left basically (unless not main screen and so 0,0 is not valid)
        frame = { x = 0, y = 0, w = 1, h = 1 }
        -- frame = hs.screen.mainScreen():frame() -- this makes it cover whole screen... another option, that might be confusing
        -- perhaps special color for app/window levels vs other elements?
    elseif not frame then
        onlyAlert("no frame: " .. role)
        print("no frame: " .. role)
        return
    end
    -- sometimes the frame is off screen... like a scrolled window (i.e. hammerspoon console)...
    --   would I cap its border with the boundaries of a parent element?

    -- PRN:
    --   what if element has no width/height or neither?
    --   what if element is off screen? how can I tell?
    --      i.e. in iTerm if I go up to level of window buttons and keep moving right through siblings, I encounter extra text elements that are negative y only... so above the window? (when iTerm is maximized window - not full screen)
    --          frame	{ h = 16.0, w = 16.0, x = 26.0, y = -21.0 }
    --          frame	{ h = 16.0, w = 16.0, x = 46.0, y = -21.0 }
    --          frame	{ h = 16.0, w = 16.0, x = 6.0, y = -21.0 }

    M.last.callout = canvas.new(frame)
        :appendElements({
            action = "strokeAndFill",
            padding = 0,
            type = "rectangle",
            fillColor = { red = 1, blue = 0, green = 0, alpha = 0.1 },
            strokeColor = { red = 1, blue = 0, green = 0, alpha = 0.5 },
            strokeWidth = 4,
        }):show()

    showTooltipForElement(element, frame)
end

local function highlightCurrentElement()
    assert(M.last ~= nil)

    local pos = hs.mouse.absolutePosition()
    local element = hs.axuielement.systemElementAtPosition(pos)
    if element == M.last.element then
        -- skip if same element
        return
    end

    highlightThisElement(element)
end

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "C", function()
    -- copy last script to clipboard... maybe just do this on stop?
    if M.last.text then
        hs.pasteboard.setContents(M.last.text)
    end
end)

local function stopElementInspector()
    M.moves = nil
    M.subscription:unsubscribe() -- subscription cleanup is all... really can skip this here
    removeHighlight() -- clear the callout/tooltips
    if M.stop_event_source then
        -- separately need to stop the upstream event source (do not comingle unsub w/ stop source, usually you might have multiple subs and would want to separately control the subs vs source)
        M.stop_event_source()
        M.stop_event_source = nil
    end

    for _, binding in pairs(M.bindings) do
        binding:delete()
    end
end

-- local function cycleSegments()
--     -- TODO yes you can navigate sections:
--     --   for now just use Script Debugger until this provies useful
--     AXSections: [
--       [SectionUniqueID: AXToolbar, SectionDescription: Toolbar, SectionObject: hs. axuielement: AXToolbar (0x60000391bf38)
--       [SectionUniqueID: AXContent, SectionDescription: Content, SectionObject: hs. axuielement: AXScrollArea
--       ...
--     ]
--     -- in testing in Script Debugger... I don't think there is a reference to the element anyways, seems to just be an ID ref (not even unique even though it is called unique in Script Debugger's explroer... for now lets disable this)
--     -- IIRC only windows have AxSections
--     hs.alert.show("Cycling AxSections")
--     M.last.cycle = "AxSections"
-- end

local function cycleChildren()
    hs.alert.show("Cycling AXChildren")
    M.last.cycle = "AXChildren"
end

local function cycleChildrenInNavigationOrder()
    hs.alert.show("Cycling AXChildrenInNavigationOrder")
    M.last.cycle = "AXChildrenInNavigationOrder"
end

local function startElementInspector()
    M.moves, M.stop_event_source = require("config.rx.mouse").mouseMovesThrottledObservable(50)
    M.subscription = M.moves:subscribe(
        function()
            -- stream is just move alert not position
            highlightCurrentElement()
        end
    -- function(error)
    --     -- right now my sources don't levearge error (nor complete) events... so just ignore
    --     print("[ERROR] what to do here?", error)
    -- end,
    -- function()
    --     print("[COMPLETE] what to do here?")
    -- end
    )
    table.insert(M.bindings, hs.hotkey.bind({}, "escape", stopElementInspector))
    -- table.insert(M.bindings, hs.hotkey.bind({}, "s", cycleSegments))
    -- table.insert(M.bindings, hs.hotkey.bind({}, "c", cycleChildren))
    -- table.insert(M.bindings, hs.hotkey.bind({}, "n", cycleChildrenInNavigationOrder))
end

M.moves = nil
M.stop_event_source = nil
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "T", function()
    alert.closeAll()
    if not M.moves then
        startElementInspector()
        highlightCurrentElement() -- don't need to move mouse to highlight first element
    else
        stopElementInspector()
    end
end)

local function getSiblings(element)
    if not element then
        print("no element to move")
        return
    end
    local parent = element:attributeValue("AXParent")
    if not parent then
        print("no parent")
        return
    end
    local cycle = M.last.cycle or "AXChildren"
    return parent:attributeValue(cycle)
end

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "up", function()
    alert.closeAll() -- any alerts should be closed to avoid confusion

    -- move up to parent!
    if not M.moves then
        return
    end

    local role = M.last.element:attributeValue("AXRole")
    if role == "AXApplication" then
        onlyAlert("already at top: AXApplication")
        return
    end

    local parent = M.last.element:attributeValue("AXParent")
    if parent == M.last.element then
        onlyAlert("already at top")
        return
    end
    if not parent then
        print("unexpected: no parent")
        return
    end
    highlightThisElement(parent)
end)

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "down", function()
    alert.closeAll()

    -- move down to child!
    if not M.moves then
        return
    end
    local cycle = M.last.cycle or "AXChildren"
    local children = M.last.element:attributeValue(cycle)
    if not children or #children == 0 then
        print("no " .. cycle, children)
        onlyAlert("no " .. cycle)
        return
    end
    highlightThisElement(children[1])
end)

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "right", function()
    alert.closeAll()
    -- PRN consider binding right to left/right ... like escape, remove only use binding while in observing mode
    if not M.moves then
        return
    end
    local function nextSibling(element)
        local siblings = getSiblings(element)
        if not siblings then
            print("no sibling " .. M.last.cycle)
            return
        end
        for i, child in ipairs(siblings) do
            if child == element and i < #siblings then
                return siblings[i + 1] -- Return next sibling
            end
        end
        -- TODO if element is not last then that means it was not in the list...
        --   TODO jump to last item in that case? or first?
        --   this is needed for cycling AXSections
        print("no next sibling " .. M.last.cycle)
    end
    local next = nextSibling(M.last.element)
    if not next then
        onlyAlert("no next sibling " .. M.last.cycle)
        return
    end
    highlightThisElement(next)
end)

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "left", function()
    alert.closeAll()
    if not M.moves then
        return
    end
    local function previousSibling(element)
        local siblings = getSiblings(element)
        if not siblings then
            print("no siblings " .. M.last.cycle)
            return
        end
        for i, child in ipairs(siblings) do
            if child == element and i > 1 then
                return siblings[i - 1] -- Return previous sibling
            end
        end
    end
    local prev = previousSibling(M.last.element)
    if not prev then
        onlyAlert("no previous sibling " .. M.last.cycle)
        return
    end
    highlightThisElement(prev)
end)

local function testHighlightOnReloadConfig()
    -- tmp testing specific control
    local fcpx = hs.axuielement.applicationElement(hs.application.find("Final Cut Pro"))
    -- local target = fcpx:window(2):splitGroup(1):group(2) -- AXTitleUIElement test case
    -- local target = fcpx
    local target = fcpx:window(2)
    highlightThisElement(target)
end

-- testHighlightOnReloadConfig()

local function testCaching()
    local fcpx = CachedElement.forApp("Final Cut Pro")
    print("fcpx", fcpx)

end

testCaching()

return M

-- NOTES
-- - iTerm2 + nvim => sets AXDocument attribute with path to currentcurrent  file
