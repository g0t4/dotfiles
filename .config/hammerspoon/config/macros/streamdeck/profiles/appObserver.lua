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
---@param appTitle string
---@param page number
---@param appObserver AppObserver
function changePage(deckName, appTitle, page, appObserver)
    return function()
        -- pass deckName so you can use a button on a different deck to change another deck's page
        --   so long as both decks are claimed by same observer that seems reasonable
        --   most page buttons are for the same deck BTW (all I've used so far)
        --   if need to set pages across observers, will figure that out later then
        local deck = appObserver.claimedDecks[deckName]
        if not deck then
            hs.notify.show("Deck not claimed, cannot change its page, see hs console")
            print("Deck not claimed, cannot change its page: ", deckName,
                "app:", quote(appTitle)
                "page:", page,
                "observer:", appObserver)
            return
        end

        pageSettings.setSavedPageNumber(deckName, appTitle, page)

        -- TODO! after load profile for second page, the original page is still present? I see it in the timing logs when I change pages left/right
        appObserver:loadProfileForDeck(deck)
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
---@field appTitle string
---@field intraAppObserver hs.axuielement.observer|nil
---@field claimedDecks table<string, DeckController> # currently controlled by this observer
---@field private registeredDecks table<string, boolean> # decks that have registered pages (really shouldn't be used externally)
local AppObserver = {}
AppObserver.__index = AppObserver

---@param appTitle string
---@return AppObserver
function AppObserver:new(appTitle)
    local o = setmetatable({}, AppObserver)
    o.claimedDecks = {}
    o.registeredDecks = {}
    o.profiles = {}
    o.appTitle = appTitle
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
    local profile = Profile:new("n/a", self.appTitle, deckName)
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
    -- print("  activate " .. quote(self.appTitle)) -- TMP TIMING ANALYSIS
    f.each(unclaimedDecks, function(_, deck)
        self:tryClaimNewDeck(deck)
    end)

    self:setupIntraAppObserver()
end

function AppObserver:deactivate()
    if self.intraAppObserver then
        self.intraAppObserver:stop()
        self.intraAppObserver = nil
    end
    f.each(self.claimedDecks, function(_, deck)
        -- TODO push this into deckController?
        f.each(deck.buttons.buttons, function(_, button)
            -- TODO push this into buttonsController?
            -- primarily to stop buttons like ClockButton (that have a timer)
            -- STOP does not clear/reset the image
            button:stop()
        end)
    end)
end

---@param deck DeckController
function AppObserver:tryClaimNewDeck(deck)
    if not self.registeredDecks[deck.name] then
        -- reject deck
        return false
    end

    -- print("  " .. deck.name .. " claimed by " .. self.appTitle)
    -- claim deck and load its profile
    self.claimedDecks[deck.name] = deck
    self:loadProfileForDeck(deck)
    return true
end

function AppObserver:onModSetChanged()
    for _, deckController in pairs(self.claimedDecks) do
        self:loadProfileForDeck(deckController, true)
    end
end

---@param deck DeckController
---@param isModSetChange boolean|nil
function AppObserver:loadProfileForDeck(deck, isModSetChange)
    -- print("    " .. deck.name) -- TMP TIMING ANALYSIS
    local pageNumber = pageSettings.getSavedPageNumber(deck.name, self.appTitle)

    -- local startTime = get_time() -- TMP TIMING ANALYSIS

    local page = self:getProfilePage(deck, pageNumber)

    if page == nil and pageNumber ~= 1 then
        -- Try page 1 if the saved page # doesn't exist
        pageSettings.clearSavedPageNumber(deck.name, self.appTitle)
        pageNumber = 1
        page = self:getProfilePage(deck, 1)
    end

    if page == nil then
        print("Registered deck " .. deck.name ..
            " is missing expected page #" .. pageNumber,
            "available pages:", hs.inspect(f.keys(self.profiles)))
        return false
    end

    -- startTime = get_time() -- TMP TIMING ANALYSIS
    page:applyTo(deck, isModSetChange)
    -- print("      applyTo " .. get_elapsed_time_in_milliseconds(startTime) .. "ms") -- TMP TIMING ANALYSIS
    return true
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
