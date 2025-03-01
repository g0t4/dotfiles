local Profile = require "config.macros.streamdeck.profile"
---





---@class AppObserver
---@field profiles table<string, Profile> @deckName -> Profile
---@field appName string
local AppObserver = {}
AppObserver.__index = AppObserver

---@param appName string
---@return AppObserver
function AppObserver:new(appName)
    local o = setmetatable({}, AppObserver)
    o.profiles = {}
    o.appName = appName
    return o
end

---@param deckName string
---@param pageNumber number|nil
function AppObserver:getProfile(deckName, pageNumber)
    -- TODO later add in app observations too (and allow updating profiles/buttons!)
    pageNumber = pageNumber or 1
    local key = deckName .. "-" .. pageNumber
    return self.profiles[key]
end

---@param deckName string
---@param getButtons (fun(self, deck: DeckController): PushButton[])|nil
---@param getEncoders (fun(self, deck: DeckController): Encoder[])|nil
---@param pageNumber number|nil
function AppObserver:addProfile(deckName, getButtons, getEncoders, pageNumber)
    local profile = Profile:new("n/a", self.appName, deckName)
    pageNumber = pageNumber or 1
    key = deckName .. "-" .. pageNumber
    self.profiles[key] = profile
    if getButtons ~= nil then
        profile.buttons = getButtons
    end
    if getEncoders ~= nil then
        profile.encoders = getEncoders
    end
end

return AppObserver
