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
