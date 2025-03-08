local MaestroButton = require("config.macros.streamdeck.maestroButton")
local KeyStrokeButton = require("config.macros.streamdeck.keystrokeButton")
local LuaButton = require("config.macros.streamdeck.luaButton")
local AppObserver = require("config.macros.streamdeck.profiles.appObserver")
local ClockButton = require("config.macros.streamdeck.clockButton")
local Encoder = require("config.macros.streamdeck.encoder")
local CommandButton = require("config.macros.streamdeck.commandButton")
local AppButton = require("config.macros.streamdeck.appButton")
local f = require("config.helpers.underscore")


local DefaultsProfiles = AppObserver:new(APPS.Defaults)

DefaultsProfiles:addProfilePage(DECK_1XL, PAGE_1, function(_, deck)
    return {
        -- * row 1
        ClockButton:new(1, deck),

        LuaButton:new(6, deck, appIconHammerspoon(), hs.openConsole),
        LuaButton:new(7, deck, drawTextIcon("Clear Console", deck), hs.console.clearConsole),
        LuaButton:new(8, deck, drawTextIcon("Reload Config", deck), hs.reload),

        -- * row 2
        LuaButton:new(16, deck, drawTextIcon("Toggle Record", deck), function() Record:toggle() end),

        LuaButton:new(11, deck, drawTextIcon("Corner Camera", deck), Scenes.setScreenCornerCamera),
        LuaButton:new(12, deck, drawTextIcon("Screen Only", deck), Scenes.setScreenOnly),
        LuaButton:new(13, deck, drawTextIcon("Camera Only", deck), Scenes.setCameraOnly),
        LuaButton:new(14, deck, drawTextIcon("Screen with Huge Camera", deck), Scenes.setScreenWithHugeCamera),



        -- * row 3


        -- * row 4
        -- open folder button
        --   movies dir
        --   screenshots dir
        -- open app button
        --   for app switcher?
        -- CommandButton:new(31, deck, appIcon("com.apple.Finder"), { "open", "~/Pictures/Screencaps" }),
        CommandButton:new(31, deck, hsIcon("files/camera-dir-elgato72.png"), { "open", "~/Pictures/Screencaps" }),
        CommandButton:new(32, deck, hsIcon("files/movies-dir-elgato72.png"), { "open", "~/Movies2" }),

    }
end)

DefaultsProfiles:addProfilePage(DECK_4PLUS, PAGE_1,
    function(_, deck)
        -- PRN => static app switcher buttons
        --     => good news is can be computed once during app activation (if a neww app)
        -- FUTURE => dynamic app switcher buttons in default profile here...
        return {
            -- *** row 1
            -- TODO app switcher
            -- TODO if using icns, make sure to cache the file
            AppButton:new(1, deck, "com.apple.finder"),

            -- *** row 2
        }
    end,
    function(_, deck)
        return {
            -- FYI could use touch screen in some cases for app switcher! can detect 8+ buttons on it!
            --  then no click sound?
        }
    end
)

return DefaultsProfiles
