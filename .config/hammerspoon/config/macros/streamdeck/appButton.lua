local PushButton = require("config.macros.streamdeck.pushButton")
require("config.macros.streamdeck.iconHelpers")
require("config.macros.streamdeck.helpers")

---@class AppButton : PushButton
---@field appBundleID string
local AppButton = setmetatable({}, { __index = PushButton })
AppButton.__index = AppButton -- for __tostring

--- only pass one of appBundleID or appPath
---@param buttonNumber number
---@param deck DeckController
---@param appBundleID string|nil # PREFER - i.e. "com.apple.finder"
---@param appFullPath string|nil # full path "/Applications/Foo.app"
---@return AppButton
function AppButton:new(buttonNumber, deck, appBundleID, appFullPath)
    if (not appBundleID) and appFullPath then
        -- only necessary if bundleID is not definitive
        -- TODO check timing and warn if way slower so user can update button to use bundleID?
        --   if an app is present multiple times, does its bundleID change for each instance (i.e. .2)?
        local info = hs.application.infoForBundlePath(appFullPath)
        if info and info.CFBundleIdentifier then
            appBundleID = info.CFBundleIdentifier
        else
            print("WARNING: appBundleID not found for appPath... the button will not work: ", appFullPath)
        end
    end
    assert(appBundleID, "appBundleID or appPath must be provided")
    local image = hs.image.imageFromAppBundle(appBundleID)

    -- PRN can get name/path from bundleID
    -- hs.application.nameForBundleID(appBundleID)
    -- hs.application.pathForBundleID(appBundleID)


    ---@class AppButton
    local o = PushButton.new(AppButton, buttonNumber, deck, image)
    o.appBundleID = appBundleID
    return o
end

function AppButton:pressed()
    -- verbose("launching app: ", self.appBundleID)
    hs.application.launchOrFocusByBundleID(self.appBundleID)
end

function AppButton:__tostring()
    return "AppButton " .. self.appBundleID
end

return AppButton
