local Profile = require "config.macros.streamdeck.profile"

--- *** LuaButton helper wrappers, though can be used in other buttons potentially (i.e. encoder buttons/gestures)

function menu(menu)
    return function()
        selectMenuItemWithFailureTroubleshooting(menu)
    end
end

---@param deckName string
---@param appModuleName string
---@param page number
function changePage(deckName, appModuleName, page)
    local pageSettings = require("config.macros.streamdeck.settings.page")
    return function()
        pageSettings.setSavedPageNumber(deckName, appModuleName, page)
    end
end

---

DECK_1XL = "1XL"
DECK_2XL = "2XL"
DECK_3XL = "3XL"
DECK_4PLUS = "4+"

PAGE_1 = 1
PAGE_2 = 2
PAGE_3 = 3
PAGE_4 = 4
PAGE_5 = 5
PAGE_6 = 6
PAGE_7 = 7
PAGE_8 = 8
PAGE_9 = 9
PAGE_10 = 10

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
function AppObserver:getProfilePage(deckName, pageNumber)
    pageNumber = pageNumber or 1
    local key = deckName .. "-" .. pageNumber
    return self.profiles[key]
end

---@param deckName string
---@param getButtons (fun(self, deck: DeckController): PushButton[])|nil
---@param getEncoders (fun(self, deck: DeckController): Encoder[])|nil
---@param pageNumber number|nil
function AppObserver:addProfilePage(deckName, pageNumber, getButtons, getEncoders)
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
