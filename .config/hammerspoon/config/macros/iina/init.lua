require("config.macros.streamdeck.menuButton")

---@return hs.axuielement
function GetIINAAppElement()
    return GetAppElement("com.colliderli.iina")
end

function IINA_PreviousFrame()
    -- TODO extract into a shared library so I am not loading my streamdeck button project with this code
    selectMenuItemWithFailureTroubleshooting("Previous Frame")
end
