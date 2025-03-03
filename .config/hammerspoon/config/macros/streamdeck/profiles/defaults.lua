local MaestroButton = require("config.macros.streamdeck.maestroButton")
local KeyStrokeButton = require("config.macros.streamdeck.keystrokeButton")
local LuaButton = require("config.macros.streamdeck.luaButton")
local AppObserver = require("config.macros.streamdeck.profiles.appObserver")
local ClockButton = require("config.macros.streamdeck.clockButton")
local Encoder = require("config.macros.streamdeck.encoder")
local CommandButton = require("config.macros.streamdeck.commandButton")
local AppButton = require("config.macros.streamdeck.appButton")
local f = require("config.helpers.underscore")


local FallbackProfiles = AppObserver:new("fallback")

FallbackProfiles:addProfilePage(DECK_1XL, PAGE_1, function(_, deck)
    return {
        -- * row 1
        ClockButton:new(1, deck),

        LuaButton:new(6, deck, appIconHammerspoon(), hs.openConsole),
        LuaButton:new(7, deck, drawTextIcon("Clear Console", deck), hs.console.clearConsole),
        LuaButton:new(8, deck, drawTextIcon("Reload Config", deck), hs.reload),

        -- * row 2


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

function serialize_table(tbl)
    if type(tbl) ~= "table" then
        return tostring(tbl) -- Handle non-table values
    end

    local result = {}
    local visited = {}

    local function serialize_inner(t)
        if visited[t] then
            return "\"<circular>\"" -- Handle circular references
        end
        visited[t] = true

        local items = {}
        for k, v in pairs(t) do
            local key = "[" .. serialize_table(k) .. "]"
            local value = serialize_table(v)
            table.insert(items, key .. "=" .. value)
        end
        table.sort(items) -- Ensure consistent order

        return "{" .. table.concat(items, ",") .. "}"
    end

    return serialize_inner(tbl)
end

function memoize(fn)
    local cache = {}
    return function(...)
        -- local key = table.concat({ ... }, ",") -- Basic key generation
        local key = f.concatValues(f.map({ ... }, function(v)
            if type(v) == "table" then
                return serialize_table(v)
            end
            return tostring(v)
        end))
        if cache[key] == nil then
            print("cache miss", key)
            cache[key] = fn(...)
        end
        return cache[key]
    end
end

local memoized_hsCircleIcon = memoize(hsCircleIcon)
-- local memoized_hsCircleIcon = hsCircleIcon -- no memoize

local function myTimingTest()
    local startTime = GetTime()
    local xlDeck = {
        buttonSize = {
            w = 96,
            h = 96
        }
    }
    local base = {
        MaestroButton:new(1, xlDeck, memoized_hsCircleIcon("#FFFF00", xlDeck),
            "foo", "Highlight color yellow"),

        MaestroButton:new(1, xlDeck, memoized_hsCircleIcon("#00FF00", xlDeck),
            "foo", "Highlight color yellow"),
        MaestroButton:new(1, xlDeck, memoized_hsCircleIcon("#00FF00", xlDeck),
            "foo", "Highlight color yellow"),
        MaestroButton:new(1, xlDeck, memoized_hsCircleIcon("#00FF00", xlDeck),
            "foo", "Highlight color yellow"),

        -- #FCE5CD (highlight light orange 3) => increase saturation for button color: #FFC690
        MaestroButton:new(2, xlDeck, memoized_hsCircleIcon("#FFC690", xlDeck, "rec"),
            "foo", "highlight light orange 3"),

        -- "none" == remove highlight (background color)
        MaestroButton:new(3, xlDeck, memoized_hsCircleIcon("#FFFFFF", xlDeck, "none"),
            "foo", "highlight none"),

        -- -- changes text color (not highlight) => looks nice! (could be veritcal middle aligned but this is FINE for now)
        -- MaestroButton:new(9, xlDeck, drawTextIcon("dark green 2", xlDeck,
        --         { color = { hex = "#38761D" }, font = { size = 30 } }),
        --     "foo", "dark green 2"),

        -- KeyStrokeButton:new(5, xlDeck, drawTextIcon("⇒", xlDeck), {}, "⇒"),
    }
    print("myTestFunc took " .. GetElapsedTimeInMilliseconds(startTime) .. "ms")
end


FallbackProfiles:addProfilePage(DECK_2XL, PAGE_1, function(_, deck)
    return {
        -- row 4:
        LuaButton:new(32, deck, drawTextIcon("Timing Test", deck), myTimingTest)
    }
end)

FallbackProfiles:addProfilePage(DECK_4PLUS, PAGE_1,
    function(_, deck)
        -- PRN => static app switcher buttons
        --     => good news is can be computed once during app activation (if a neww app)
        -- FUTURE => dynamic app switcher buttons in default profile here...
        return {
            -- *** row 1
            AppButton:new(1, deck, "com.apple.finder"),
            -- AppButton:new(1, deck, nil, "/System/Library/CoreServices/Finder.app"),


            -- TODO app switcher
            -- *** row 2
        }
    end,
    function(_, deck)
        return {
            -- TODO setup touch screen button gesture! for corresponding encoder
            Encoder:new(1, deck, hsIcon("test-svgs/hanging-96.png")),
            Encoder:new(2, deck, hsIcon("test-svgs/saggy-64.png")),
            Encoder:new(3, deck, hsIcon("test-svgs/stick.svg")),
            Encoder:new(4, deck, hsIcon("test-svgs/purple-pink-128.png"))
        }
    end
)

return FallbackProfiles
