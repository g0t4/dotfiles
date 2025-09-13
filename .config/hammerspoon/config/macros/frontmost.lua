---@param menu string
function PressMenuItemRegex(menu)
    PressMenuItem(menu, true)
end

---@param menu string|table -- matching text or table of nested menus
---@param is_regex boolean -- default false
function PressMenuItem(menu, is_regex)
    is_regex = is_regex or false

    local frontmostApp = hs.application.frontmostApplication()

    local succeeded = frontmostApp:selectMenuItem(menu, is_regex)
    if succeeded then
        return
    end

    print("Failed to SELECT menu item for " .. hs.inspect(menu))

    local menuItem = frontmostApp:findMenuItem(menu)
    -- menuItem has "enabled" and "ticked" fields
    --    https://www.hammerspoon.org/docs/hs.application.html#bundleID
    --    FYI if app is not in foreground then all menu items are disabled
    if menuItem == nil then
        local debugFile = "~/.hammerspoon/menu-dump.lua"
        local message = "Failed to find menu item, dumping all menu items to " .. debugFile
        print(message)
        hs.alert.show(message)
        frontmostApp:getMenuItems(function(items)
            local file = io.open(resolve_home_path(debugFile), "w")
            file:write(hs.inspect(items))
            file:close()
        end)
    end
end
