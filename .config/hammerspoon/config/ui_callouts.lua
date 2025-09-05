local canvas = require("hs.canvas")
local alert = require("hs.alert")
local CachedElement = require("config.ax.caching")

local M = {}
M.last = {
    ---@type hs.axuielement|nil
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
    local rows = {}
    for k, v in pairs(value) do
        local text = ""
        if name == "AXSections" then
            -- FYI section entries have 3 attrs (keep each entry on one line):
            --  SectionObject: AXScrollArea<hs.axuielement> - ** seems most important, the object itself :)
            --  SectionUniqueID: AXContent<string>
            --  SectionDescription: Toolbar<string>
            local nestedAttrs = {}
            for k2, v2 in pairs(v) do
                table.insert(nestedAttrs, k2 .. ": " .. tostring(v2))
            end
            text = text .. k .. ": " .. table.concat(nestedAttrs, ", ")
        elseif type(v) == "userdata" then
            text = text .. k .. ": " .. displayUserData(k, v)
            text = text .. displayType(v)
        else
            text = text .. k .. ": " .. tostring(v)
            text = text .. displayType(v)
        end
        table.insert(rows, text)
    end
    if #rows < 2 then
        -- zero / one element => no new lines, use concat to avoid 0/1 handling
        return "[" .. table.concat(rows, "") .. "]"
    end
    --  for multiple, then make sure first is on its own line and closing ] is on own line for readability
    return "[\n  " .. table.concat(rows, "\n  ") .. "\n]"
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
        if attrValue == "" then goto continue end -- skip empty values, i.e. empty AXDescription

        local value = displayAttribute(attrName, attrValue) or ""
        if TableContains({ "AXValue" }, attrName) then
            -- notoriously long values (i.e. AXValue for iTerm2 window)
            --  and by long I mean like 30 lines (tooltip is entire screen)...
            --  don't worry about things like CustomContent that can be 10 short lines long
            --  I wanna see that stuff that is odd even if a smidge long
            if #value > 80 then
                value = value:sub(1, 80) .. " <TRUNCATED>"
            end
        end
        table.insert(attributes, attrName .. ": " .. value .. displayType(attrValue))

        ::continue::
    end

    if M.last.showChildren then
        function appendChildren(children)
            for _, child in ipairs(children) do
                -- TODO what attrs should I show? any others?
                local role = child:attributeValue("AXRole")
                local subrole = child:attributeValue("AXSubrole")
                local title = child:attributeValue("AXTitle")
                local description = child:attributeValue("AXDescription")
                local childText = role
                if subrole then
                    childText = childText .. "(" .. subrole .. ")"
                end
                childText = childText .. ":"
                if title then
                    childText = childText .. " " .. quote(title)
                end
                if description then
                    childText = childText .. " desc:" .. quote(description)
                end
                table.insert(attributes, childText)
            end
        end

        table.insert(attributes, "\nAXChildren:")
        appendChildren(element:attributeValue("AXChildren") or {})

        table.insert(attributes, "\nAXChildrenInNavigationOrder:")
        appendChildren(element:attributeValue("AXChildrenInNavigationOrder") or {})

        -- FYI right now AXSections shows in list of attrs
    else
        -- PRN if styled text, could make it italic
        table.insert(attributes, "\npress 'c' to show children")
    end
    local attribute_dump = table.concat(attributes, "\n")

    --- @param elem hs.axuielement
    local function getUniqueSpecifierChainForElementSearch(elem)
        local chain = elem:path()
        assert(chain ~= nil)

        ---@param e hs.axuielement
        ---@return string | nil @ nil == ambiguous (no unique ref)
        local function buildRef(e)
            local parent = e:axParent()
            local role = e:axRole()

            if role == "AXApplication" then
                return "app"
            end

            local siblings = parent:childrenWithRole(role)
            if #siblings == 1 then
                -- PRN call into findUniquReference anyways and then fallback to index? in this case?
                if e:isAttributeValueUnique("AXTitle") then
                    -- prefer title over index
                    -- also I far prefer to see a title than an index, feels like I should add this to my other lua ref that isn't just on unique! (top of ui callout)
                    return ":" .. e:singular() .. "(" .. axTitleQuoted(e) .. ")"
                end
                return ":" .. e:singular() .. "(1)"
            end
            local uniqueRef = e:findUniqueReference()
            if uniqueRef == nil then return nil end
            return ":" .. uniqueRef

            -- TODO propose search criteria of the target element too? or leave that up to using the listed attrs?
        end

        -- PRN what if I ran timing code to find the fastest element start too OR estimated this based on # of total descendents?
        --  do this at each level of possible unique path... and pick the most general one that is the closest to the fastest route?
        --  most of the time it's gonna be a window most likely and then a panel that has a subset for a second search within
        --  probably make this a separate flag or keymap?

        local lines = { "unique ref: " }
        for _, currentElement in ipairs(chain) do
            local ref = buildRef(currentElement)
            if not ref then
                -- nothing to add to accessor b/c it was ambiguous
                break
            end
            table.insert(lines, ref)
        end

        return ConcatIntoLines(lines)
    end

    local elementSearchCode = getUniqueSpecifierChainForElementSearch(element)

    attribute_dump = attribute_dump .. "\n\n" .. elementSearchCode

    -- include everything in copy so I can get attr values without writing them down by hand! (for cmd-ctrl-alt-c)
    M.last.text = specifierLua .. "\n\n" .. attribute_dump


    local styledSpecifier = hs.styledtext.new(specifierLua, {
        font = {
            name = "SauceCodePro Nerd Font",
            size = 14
        },
        color = { white = 1 },
    })

    local styledAttributes = hs.styledtext.new(attribute_dump, {
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

---@return boolean
local function is_highlighting_now()
    return M.last.tooltip ~= nil
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

---@param redo_highlight? boolean
local function highlightCurrentElement(redo_highlight)
    redo_highlight = redo_highlight or false
    assert(M.last ~= nil)
    if M.last.freeze then
        return
    end


    local pos = hs.mouse.absolutePosition()
    local element = hs.axuielement.systemElementAtPosition(pos)
    if element == M.last.element and not redo_highlight then
        -- skip if same element
        return
    end

    highlightThisElement(element)
end

---@return hs.axuielement? element
local function get_current_element()
    if M.last.freeze then
        return
    end

    local pos = hs.mouse.absolutePosition()
    ---@type hs.axuielement?
    local element = hs.axuielement.systemElementAtPosition(pos)
    if element == nil then
        print("no current element")
        return
    end

    return element
end

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
    M.bindings = {}
end

local function toggle_show_children()
    M.last.showChildren = not M.last.showChildren
    highlightCurrentElement(true)
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
    table.insert(M.bindings, hs.hotkey.bind({}, "c", toggle_show_children))
end

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "F", function()
    -- toggle freeze to leave it open instead of needing to copy or screencap
    M.last.freeze = not M.last.freeze
end)

function capture_element_under_mouse()
    -- this can work w/o using highlighter!
    local element = get_current_element()
    if element == nil then
        print("no frame found for current element, cannot capture it")
        return
    end
    local frame = element:axFrame()

    local role = element:axRole() or ""
    local identifier = element:attributeValue("AXIdentifier") or ""
    local value = element:attributeValue("AXValue") or ""
    local title = element:attributeValue("AXTitle") or ""
    local desc = element:attributeValue("AXDescription") or ""
    local image_tag = role
    if identifier then image_tag = image_tag .. "_id_" .. identifier end
    if value then image_tag = image_tag .. "_value_" .. value end
    if title then image_tag = image_tag .. "_title_" .. title end
    if desc then image_tag = image_tag .. "_desc_" .. desc end
    image_tag = sanitize_image_tag(image_tag)

    local was_highlighting = is_highlighting_now()
    removeHighlight()

    -- * save to
    local where_to = getScreencaptureFileName("png", image_tag)
    -- local where_to = "-P" -- -P == open in preview (does not save to disk)

    function when_done(result, stdOut, stdErr)
        if result ~= 0 then
            hs.alert.show("capture failed: " .. stdErr)
            print("capture failed", stdErr)
        end
        if was_highlighting then
            highlightCurrentElement()
        end

        print("element captured to " .. where_to)
    end

    -- * rectangle
    -- screencapture uses `-R <x,y,w,h>`
    local rectangle = string.format("%d,%d,%d,%d", frame.x, frame.y, frame.w, frame.h)
    print("rectange: " .. rectangle)

    hs.task.new("/usr/sbin/screencapture", when_done, { "-o", "-R", rectangle, where_to }):start()
end

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "p", capture_element_under_mouse)

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
    local fcpx = hs.axuielement.applicationElement(hs.application.find(APPS.FinalCutPro))
    -- local target = fcpx:window(2):splitGroup(1):group(2) -- AXTitleUIElement test case
    -- local target = fcpx
    local target = fcpx:window(2)
    highlightThisElement(target)
end

-- testHighlightOnReloadConfig()

local function testCaching()
    local fcpx = CachedElement.forApp(APPS.FinalCutPro)
    -- local fcpx = hs.axuielement.applicationElement(hs.application.find(APPS.FinalCutPro))
    local startTime = get_time()
    for i = 1, 10 do
        -- print("caching - iteration", i)
        local attrs = fcpx:attributes() -- 100 calls => ~8ms avg
        -- local attrs = fcpx:allAttributeValues() -- 100 calls => 90ms avg (no caching), 1000 calls => 2,500ms!
    end
    print("fcpx", fcpx)
    print("caching - took", get_time() - startTime)
end

-- testCaching()

return M

-- NOTES
-- - iTerm2 + nvim => sets AXDocument attribute with path to currentcurrent  file
