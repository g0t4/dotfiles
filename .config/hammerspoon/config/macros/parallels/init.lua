function Parallels_CloseFocusedWindow()
    -- because Parallels Desktop, in their fucking infinite wisdom, decided to disable Cmd+W for all windows in the app
    --  and the app constantly pops up the fucking "make a new VM wysiwg fucking window every time you remove your last VM... so all the time when using packer to build new VMs..."
    --  and you cannot close it with cmd fucking W
    local win = hs.window.focusedWindow()
    if not win then
        return false
    end

    local ax = hs.axuielement.windowElement(win)
    if not ax then
        return false
    end

    local close = ax:attributeValue("AXCloseButton")
    if close then
        close:performAction("AXPress")
        return true
    end

    return false
end

function Parallels_ControlCenter()
    local app = hs.application.get("Parallels Desktop")
    if not app then
        print("Parallels Desktop not running")
        return
    end
    local menuPath = { "Window", "Control Center" }
    local success = app:selectMenuItem(menuPath)
    if not success then
        print("Failed to select Control Center menu item")
    end
end
