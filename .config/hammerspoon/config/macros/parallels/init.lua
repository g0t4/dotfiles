function ParallelsX_control_center()
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
