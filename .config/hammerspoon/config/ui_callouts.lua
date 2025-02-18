local M = {}
M.last = {
    element = nil,
    tooltip = nil,
    callout = nil,
    script = nil,
    escBinding = nil,
}

-- FYI use require so I get LS completions, docs, etc => globals don't work well w/ LSP
local canvas = require("hs.canvas")
local alert = require("hs.alert")
local function showTooltipForElement(element, frame)
    if not element then return end

    -- TODO copy to clipboard -- maybe do it by default when in scan mode?
    -- TODO add pause mode that doesn't hide callout/tooltip... but freezes it (maybe that is when to copy it!)
    --    register opt key or smth like that and unregister it when hide callout/tooltip

    -- PRN could add coloring of text if I can show an html element in canvas
    local clauses = BuildAppleScriptTo(element, false)
    M.last.script = CombineClausesWithLineContinuations(clauses)

    local tmpcanvas = canvas.new({ x = 0, y = 0, w = 1000, h = 1000 })
    local estimatedSizeForDefaultFont = tmpcanvas:minimumTextSize(M.last.script)
    local useFontSize = 14
    local defaultTextStyle = canvas.defaultTextStyle()
    -- *** SUPER HACK to get font sizing to work... this works though!
    --    BTW font height estimate is off, could find factor for it but for 14 point it will work with default at 27pt so I won't adjust it for now...
    -- print("defaultTextStyle", hs.inspect(defaultTextStyle))
    local ratio = useFontSize / defaultTextStyle.font.size
    local textWidth = estimatedSizeForDefaultFont.w * ratio * 1.2
    local textHeight = estimatedSizeForDefaultFont.h * ratio * 1.2
    -- add padding (don't subtract it from needed width/height)
    local padding = 10
    local tooltipWidth = textWidth + 2 * padding
    local tooltipHeight = textHeight + 2 * padding

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

    M.last.tooltip = canvas.new({ x = x, y = y, w = tooltipWidth, h = tooltipHeight })
        :appendElements({
            -- Background box
            {
                type = "rectangle",
                action = "fill",
                frame = { x = 0, y = 0, w = tooltipWidth, h = tooltipHeight },
                fillColor = { white = 0, alpha = 0.8 }, -- Dark semi-transparent background
                roundedRectRadii = { xRadius = 8, yRadius = 8 }
            },
            {
                type = "text",
                text = M.last.script,
                textSize = useFontSize,
                textColor = { white = 1 },
                frame = { x = padding, y = padding, w = tooltipWidth - 2 * padding, h = tooltipHeight - 2 * padding },
                textAlignment = "left"
            }
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

    local frame = element:attributeValue("AXFrame")
    if not frame then
        print("no frame", hs.inspect(element))
    end
    -- sometimes the frame is off screen... like a scrolled window (i.e. hammerspoon console)...
    --   would I cap its border with the boundaries of a parent element?

    M.last.callout = canvas.new(frame)
        :appendElements({
            action = "stroke",
            padding = 0,
            type = "rectangle",
            fillColor = { red = 1, blue = 0, green = 0 },
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
    if M.last.script then
        hs.pasteboard.setContents(M.last.script)
    end
end)

local function stopObserving()
    M.moves = nil
    M.subscription:unsubscribe() -- subscription cleanup is all... really can skip this here
    removeHighlight() -- clear the callout/tooltips
    if M.stop_event_source then
        -- separately need to stop the upstream event source (do not comingle unsub w/ stop source, usually you might have multiple subs and would want to separately control the subs vs source)
        M.stop_event_source()
        M.stop_event_source = nil
    end
    if M.escBinding then
        M.escBinding:delete()
        M.escBinding = nil
    end
end

local function startObserving()
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
    M.escBinding = hs.hotkey.bind({}, "escape", stopObserving)
end

M.moves = nil
M.stop_event_source = nil
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "T", function()
    if not M.moves then
        startObserving()
    else
        stopObserving()
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
    return parent:attributeValue("AXChildren")
end

local function onlyAlert(message)
    alert.closeAll()
    alert.show(message)
    print(message)
end

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "up", function()
    -- move up to parent!
    if not M.moves then
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
    local role = parent:attributeValue("AXRole")
    if role == "AXApplication" then
        onlyAlert("already at top: AXApplication")
        return
    end

    highlightThisElement(parent)
end)

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "down", function()
    -- move down to child!
    if not M.moves then
        return
    end
    local children = M.last.element:attributeValue("AXChildren")
    if not children or #children == 0 then
        onlyAlert("no children")
        return
    end
    highlightThisElement(children[1])
end)

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "right", function()
    -- PRN consider binding right to left/right ... like escape, remove only use binding while in observing mode
    if not M.moves then
        return
    end
    local function nextSibling(element)
        local siblings = getSiblings(element)
        if not siblings then
            print("no siblings")
            return
        end
        for i, child in ipairs(siblings) do
            if child == element and i < #siblings then
                return siblings[i + 1] -- Return next sibling
            end
        end
    end
    local next = nextSibling(M.last.element)
    if not next then
        onlyAlert("no next sibling")
        return
    end
    highlightThisElement(next)
end)

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "left", function()
    if not M.moves then
        return
    end
    local function previousSibling(element)
        local siblings = getSiblings(element)
        if not siblings then
            print("no siblings")
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
        onlyAlert("no previous sibling")
        return
    end
    highlightThisElement(prev)
end)

return M
