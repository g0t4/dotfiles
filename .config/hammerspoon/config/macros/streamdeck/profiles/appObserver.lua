local Profile = require "config.macros.streamdeck.profile"
local pageSettings = require("config.macros.streamdeck.settings.page")

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
---@field isActive boolean
---@field watcher hs.window.filter|nil
---@field decks DecksController
local AppObserver = {}
AppObserver.__index = AppObserver

---@param appName string
---@return AppObserver
function AppObserver:new(appName)
    local o = setmetatable({}, AppObserver)
    -- TODO! padd in decksController and use that throughout, INCLUDING for new DSL for registering buttons! (remember I use deck multiple times to build button pages)
    o.decks = {} -- TODO pass and set
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

-- *** New methods for intra-app events handling
--  TODO remove this note once all is settled below (reviewed)

---@param decksController DecksController
function AppObserver:activate(decksController)
    self.isActive = true
    self:setupWatchers()
    self:refreshDecks(decksController)
end

function AppObserver:deactivate()
    self.isActive = false
    if self.watcher then
        self.watcher:stop()
        self.watcher = nil
    end
    -- Cleanup any app-specific observers here
end

---@param decksController DecksController
function AppObserver:refreshDecks(decksController)
    -- Refresh all decks with the current app's profiles
    for deckName, deckController in pairs(decksController.deckControllers) do
        self:loadProfileForDeck(deckController)
    end
end

---@param deck DeckController
function AppObserver:loadProfileForDeck(deck)
    -- FYI I have spidey senses that page number can be pushed down into the Profile? with the page it belongs to
    --   and mabye other logic can follow?
    -- PRN! technically could load the page number on module load! and only need to save new values!
    local pageNumber = pageSettings.getSavedPageNumber(deck.name, self:getModuleName())

    local selected = self:getProfilePage(deck, pageNumber)

    if selected == nil and pageNumber ~= 1 then
        -- Try page 1 if the requested page doesn't exist
        pageSettings.clearSavedPageNumber(deck.name, self:getModuleName())
        selected = self:getProfilePage(deck, 1)
    end

    if selected ~= nil then
        deck.hsdeck:reset()
        selected:applyTo(deck)
        return true
    end

    return false
end

---@param deckName string
---@param pageNumber number
function AppObserver:handlePageChange(deckName, pageNumber)
    if not self.isActive then return end

    local decksController = pageSettings.getDecksController()
    if not decksController then return end

    local deckController = decksController.deckControllers[deckName]
    if not deckController then return end

    self:loadProfileForDeck(deckController)
end

---@return string, _
function AppObserver:getModuleName()
    return self.appName:lower():gsub(" ", "")
end

---
-- Override this method in app-specific observers to handle
-- app-specific events like window changes, URL changes, etc.
---
function AppObserver:setupWatchers()
    -- Base implementation does nothing
    -- App-specific observers should override this
end

return AppObserver
