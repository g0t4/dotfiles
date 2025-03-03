local Profile = require "config.macros.streamdeck.profile"
local pageSettings = require("config.macros.streamdeck.settings.page")
local f = require("config.helpers.underscore")

--- *** LuaButton helper wrappers, though can be used in other buttons potentially (i.e. encoder buttons/gestures)

function menu(menu)
    return function()
        selectMenuItemWithFailureTroubleshooting(menu)
    end
end

---@param deckName string
---@param appNameAsSettingsKey string
---@param page number
function changePage(deckName, appNameAsSettingsKey, page)
    local pageSettings = require("config.macros.streamdeck.settings.page")
    return function()
        pageSettings.setSavedPageNumber(deckName, appNameAsSettingsKey, page)
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
---@field isActive boolean
---@field intraAppObserver hs.axuielement.observer|nil
---@field claimedDecks table<string, DeckController> # currently controlled by this observer
---@field private registeredDecks table<string, boolean> # decks that have registered pages (really shouldn't be used externally)
local AppObserver = {}
AppObserver.__index = AppObserver

---@param appName string
---@return AppObserver
function AppObserver:new(appName)
    local o = setmetatable({}, AppObserver)
    o.claimedDecks = {}
    o.registeredDecks = {}
    o.profiles = {}
    o.appName = appName
    o.isActive = false
    return o
end

---@param deck DeckController
---@param pageNumber number|nil
---@return Profile
function AppObserver:getProfilePage(deck, pageNumber)
    pageNumber = pageNumber or 1
    local key = deck.name .. "-" .. pageNumber
    return self.profiles[key]
end

---@param deckName string
---@param getButtons (fun(self, deck: DeckController): PushButton[])|nil
---@param getEncoders (fun(self, deck: DeckController): Encoder[])|nil
---@param pageNumber number|nil
function AppObserver:addProfilePage(deckName, pageNumber, getButtons, getEncoders)
    self.registeredDecks[deckName] = true
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

---@param unclaimedDecks table<string, DeckController>
function AppObserver:activate(unclaimedDecks)
    self.claimedDecks = f.where(unclaimedDecks, function(deck)
        return self.registeredDecks[deck.name]
    end)

    self.isActive = true
    self:setupIntraAppObserver()
    self:refreshDecks()
end

function AppObserver:deactivate()
    self.isActive = false
    if self.intraAppObserver then
        self.intraAppObserver:stop()
        self.intraAppObserver = nil
    end
end

function AppObserver:refreshDecks()
    for _, deckController in pairs(self.claimedDecks) do
        self:loadProfileForDeck(deckController)
    end
end

---@param deck DeckController
function AppObserver:loadProfileForDeck(deck)
    -- PRN! technically could load the page number on module load! and only need to save new values!
    local pageNumber = pageSettings.getSavedPageNumber(deck.name, self:appNameSettingsKey())

    local page = self:getProfilePage(deck, pageNumber)

    if page == nil and pageNumber ~= 1 then
        -- Try page 1 if the saved page # doesn't exist
        pageSettings.clearSavedPageNumber(deck.name, self:appNameSettingsKey())
        pageNumber = 1
        page = self:getProfilePage(deck, 1)
    end

    if page == nil then
        -- PRN add any checks here?
        print("Registered deck " .. deck.name ..
            " is missing expected page #" .. pageNumber,
            "available pages:", hs.inspect(f.keys(self.profiles)))
        return false
    end

    -- load the page
    deck.hsdeck:reset()
    page:applyTo(deck)
    return true
end

---@param deckName string
---@param pageNumber number
function AppObserver:handlePageChange(deckName, pageNumber)
    if not self.isActive then return end

    local deckController = self.claimedDecks[deckName]
    if not deckController then return end

    self:loadProfileForDeck(deckController)
end

---@return string, _
function AppObserver:appNameSettingsKey()
    -- TODO TEST PAGE CHANGES LATER... I had to fix the app modulename lookup
    --   TODO MAKE SURE MODULE NAME LOOKUP MATCHES MODULE NAMES IN profiles/foo.lua dir
    return _G.APP_MODULE_LOOKUP_BY_APP_NAME[self.appName]
end

---
-- Override this method in app-specific observers to handle
-- app-specific events like window changes, URL changes, etc.
---
function AppObserver:setupIntraAppObserver()
    -- Base implementation does nothing
    -- App-specific observers should override this
end

return AppObserver
