local PushButton = require("config.macros.streamdeck.pushButton")
require("config.macros.streamdeck.iconHelpers")
require("config.macros.streamdeck.helpers")

--- search is slow so if at all possible provide table w/ exact path
---   only need string if location changes or text changes base don app/machine/user/etc
---   PRN for string search => can pass regex param to findMenuItem (if I got that route maybe have a separate FindMenuButton? so that logic is separate?
---   ALSO could resort to LuaButton if logic is complex (don't put it all here, this is just a helper class)
---@class MenuButton : PushButton
---@field menu : table<integer, string>|string
local MenuButton = setmetatable({}, { __index = PushButton })
MenuButton.__index = MenuButton

--- pass a table for an exact menu path match
--- or, a string (regex) to search for a menu item
---@param buttonNumber number
---@param deck DeckController
---@param image hs.image
---@param menu table<integer, string>|string  # i.e. { "File", "Share", "Save Current Frame…" } or "Save Current.*"
---@return MenuButton
function MenuButton:new(buttonNumber, deck, image, menu)
    ---@class MenuButton
    local o = PushButton.new(MenuButton, buttonNumber, deck, image)
    o.menu = menu
    if menu == nil then
        error("MenuButton:new() menu param is required, it cannot be nil")
    end
    return o
end

function MenuButton:pressed()
    local menu = self.menu
    selectMenuItemWithFailureTroubleshooting(menu)
end

function selectMenuItemWithFailureTroubleshooting(menu)
    local frontmostApp = hs.application.frontmostApplication()

    local succeeded = frontmostApp:selectMenuItem(menu, true)
    if not succeeded then
        print("Failed to SELECT menu item for " .. hs.inspect(menu))

        local menuItem = frontmostApp:findMenuItem(menu)
        -- menuItem has "enabled" and "ticked" fields
        --    https://www.hammerspoon.org/docs/hs.application.html#bundleID
        --    FYI if app is not in foreground then all menu items are disabled
        if menuItem == nil then
            print("Failed to FIND menu item for " .. hs.inspect(menu))
            local debugFile = "~/.hammerspoon/menu-dump.lua"
            hs.alert.show("Failed to find menu item, dumping all menu items to " .. debugFile)
            frontmostApp:getMenuItems(function(items)
                local file = io.open(resolve_home_path(debugFile), "w")
                file:write(hs.inspect(items))
                file:close()
            end)
        else
            -- this shouldn't happen unless maybe a menu item is disabled?
            -- select has to fail and find succeeds
            hs.alert.show("Select menu item failed, but found menu item... unexpected... opening console for you")
            hs.openConsole()
            print("HOWEVER, found menu item: " .. hs.inspect(menuItem))
        end
    end
end

function MenuButton:__tostring()
    local menu = self.menu or "nil"
    if type(menu) == "table" then
        menu = table.concat(menu, " => ")
    end
    return "MenuButton " .. menu
end

return MenuButton
