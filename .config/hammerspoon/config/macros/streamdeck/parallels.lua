local verbose = require("config.macros.streamdeck.helpers").verbose

function ParallelsX_control_center()
    local app = hs.application.get("Parallels Desktop")
    if not app then
        verbose("Parallels Desktop not running")
        return
    end
    local menuPath = {"Window", "Control Center"}
    local success = app:selectMenuItem(menuPath)
    if not success then
        verbose("Failed to select Control Center menu item")
    end
end

