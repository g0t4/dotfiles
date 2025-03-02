local AppObserver = require("config.macros.streamdeck.profiles.appObserver")
local MaestroButton = require("config.macros.streamdeck.maestroButton")
local KeyStrokeButton = require("config.macros.streamdeck.keystrokeButton")
local CommandButton = require("config.macros.streamdeck.commandButton")
local verbose = require("config.macros.streamdeck.helpers").verbose
local MenuButton = require("config.macros.streamdeck.menuButton")
local LuaButton = require("config.macros.streamdeck.luaButton")
require("config.macros.streamdeck.iconHelpers")


-- TODO add in web site observer that changes buttons based on site
--   google docs I can activate my buttons for menu items like highlight colors
--   that way I don't have to dedicate a button to one purpose and waste it when on other sites
--
--
--

--

local BraveObserver = AppObserver:new(APPS.BraveBrowserBeta)

-- TODO

return BraveObserver
