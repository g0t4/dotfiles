-- require("config.macros.streamdeck.controller.menuButton") -- I think this is unused btw.. IOTW I can nuke this import most likely

---@return hs.axuielement
function GetIINAAppElement()
    return GetAppElement("com.colliderli.iina")
end
