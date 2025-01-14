hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "I", function()
    -- INSPECT ELEMENT UNDER MOUSE POSITION
    local coords = hs.mouse.absolutePosition()
    print("coords: " .. hs.inspect(coords))
    -- TODO any variance in what element is selected? isn't there another method to find element? deepest or smth?
    local elementAt = hs.axuielement.systemElementAtPosition(coords.x, coords.y)
    DumpAXAttributes(elementAt)
    DumpAXPath(elementAt)
    DumpParents(elementAt)
end)

function DumpParents(element)
    local parent = element:parent()
    print("parent", hs.inspect(parent))
    -- if parent then
    --     DumpParents(parent)
    -- end
end
