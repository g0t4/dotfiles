local AppObserver = require("config.macros.streamdeck.profiles.appObserver")
local MaestroButton = require("config.macros.streamdeck.maestroButton")
local KeyStrokeButton = require("config.macros.streamdeck.keystrokeButton")
local verbose = require("config.macros.streamdeck.helpers").verbose
local MenuButton = require("config.macros.streamdeck.menuButton")
local LuaButton = require("config.macros.streamdeck.luaButton")



-- TODO refactor to pass decks? is it worth it? probably only if it improves the button creation?
-- local cached = nil
-- function createFinderObserver(decks)  -- cache the instance once create too
--   if cached then return cached end
--   cached = AppObserver:new("Finder")
--   ... (below)

local FinderObserver = AppObserver:new("Finder")

FinderObserver:addProfilePage(DECK_3XL, PAGE_1, function(_, deck)
    return {
        -- * row 1
        -- TODO what about reflect on func name and use that as button text? debug.getinfo(foo).nparams
        LuaButton:new(1, deck, drawTextIcon("Reset Photos Dir", deck), resetPhotosDir),
        LuaButton:new(2, deck, drawTextIcon("Set Photos Dir", deck), setPhotosDir),
        -- * row 2
        -- * row 3
        -- * row 4
    }
end)



-- end
-- return createFinderObserver

return FinderObserver
