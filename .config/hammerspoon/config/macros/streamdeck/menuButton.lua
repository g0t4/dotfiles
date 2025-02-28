local PushButton = require("config.macros.streamdeck.pushButton")
require("config.macros.streamdeck.textToImage")
require("config.macros.streamdeck.helpers")

--- search is slow so if at all possible provide table w/ exact path
---   only need string if location changes or text changes base don app/machine/user/etc
---   PRN for string search => can pass regex param to findMenuItem (if I got that route maybe have a separate FindMenuButton? so that logic is separate?
---   ALSO could resort to LuaButton if logic is complex (don't put it all here, this is just a helper class)
---@class MenuButton : PushButton
---@field menu : table<integer, string>|string
local MenuButton = setmetatable({}, { __index = PushButton })
MenuButton.__index = MenuButton

--- only pass one of appBundleID or appPath
---@param buttonNumber number
---@param deck DeckController
---@param image hs.image
---@param menu table<integer, string>|string  # PREFER table with exact path, or string to search - i.e. { "File", "Open" }
---@return MenuButton
function MenuButton:new(buttonNumber, deck, image, menu)
    ---@class MenuButton
    local o = PushButton.new(MenuButton, buttonNumber, deck, image)
    o.menu = menu
    return o
end

function MenuButton:pressed()
    local frontmostApp = hs.application.frontmostApplication()
    local succeeded = frontmostApp:selectMenuItem(self.menu)
    if not succeeded then
        print("Failed to select menu item for " .. hs.inspect(self.menu))
    end
    -- PRN can check if enabled and/or ticked using findMenuItem
    --    https://www.hammerspoon.org/docs/hs.application.html#bundleID
    --    FYI if app is not in foreground then all menu items are disabled
    -- local menuItem = frontmostApp:findMenuItem(self.menu)
    --   menuItem has "enabled" and "ticked" fields
    -- if menuItem == nil then
    --     print("Failed to find menu item for " .. hs.inspect(self.menu))
    -- else
    --     menuItem:
    -- end
end

function MenuButton:__tostring()
    local menu = self.menu or "nil"
    if type(menu) == "table" then
        menu = table.concat(menu, " => ")
    end
    return "MenuButton " .. menu
end

return MenuButton
