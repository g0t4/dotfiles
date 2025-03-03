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
local TestXLDeck = {
    buttonSize = {
        w = 96,
        h = 96
    }
}

-- *** 40ms for 6 circle icons!
local function timingHsCircleOnlyNoText()
    -- TODO test setButtonColor
    -- TODO test setButtonImage (precreated and perfectly sized?) images<F7>
    local startTime = GetTime()
    local base = {
        -- *** BINGO image creation is SLOW!!!
        -- !!! (is it most of the time?... maybe reset sucked b/c I didn't reuse the same image instance?)

        MaestroButton:new(1, TestXLDeck, memoized_hsCircleIcon("#FFFF00", TestXLDeck),
            "foo", "Highlight color yellow"),

        MaestroButton:new(1, TestXLDeck, memoized_hsCircleIcon("#00FF00", TestXLDeck),
            "foo", "Highlight color yellow"),
        MaestroButton:new(1, TestXLDeck, memoized_hsCircleIcon("#00F0F0", TestXLDeck),
            "foo", "Highlight color yellow"),
        MaestroButton:new(1, TestXLDeck, memoized_hsCircleIcon("#F0FF00", TestXLDeck),
            "foo", "Highlight color yellow"),

        -- #FCE5CD (highlight light orange 3) => increase saturation for button color: #FFC690
        MaestroButton:new(2, TestXLDeck, memoized_hsCircleIcon("#FFC690", TestXLDeck, "rec"),
            "foo", "highlight light orange 3"),

        -- "none" == remove highlight (background color)
        MaestroButton:new(3, TestXLDeck, memoized_hsCircleIcon("#FFFFFF", TestXLDeck, "none"),
            "foo", "highlight none"),
    }
    print("myTestFunc took " .. GetElapsedTimeInMilliseconds(startTime) .. "ms")
end


-- *** 10-13ms for 26 images (not a huge factor)
local function timingHsIconFileOnly()
    local startTime = GetTime()
    local deck = TestXLDeck


    -- BTW 20ms is not inconsequential if it is easy to avoid b/c already caching other types, also super easy to memoize
    -- 3 hsIcon file loads => 2 to 4ms total... not bad (IIAC image size is a factor)
    -- 26 => 11-13ms
    -- TODO check image size factor (to help me size appropriately too, extra reason to get size right)
    local base = {
        MaestroButton:new(1, deck, hsIcon("pptx/colors/fill-pink.png"), "02BF881E-47AF-4812-830F-4765B6AABC41"),
        MaestroButton:new(9, deck, hsIcon("pptx/colors/line-pink.png"), "FBAD1498-E64F-4A26-8B41-59D4B59C4F6B"),
        MaestroButton:new(17, deck, hsIcon("pptx/colors/text-pink.png"), "F5068DE4-4EA3-4B4E-ABE9-44A358D380B1"),

        MaestroButton:new(2, deck, hsIcon("pptx/colors/fill-blue.png"), "D5CD851F-5A99-46E1-A922-4EF11726BD8A"),
        MaestroButton:new(10, deck, hsIcon("pptx/colors/line-blue.png"), "5250FA4D-74BE-4E29-8EFB-3F9DA4183923"),
        MaestroButton:new(18, deck, hsIcon("pptx/colors/text-blue.png"), "A8963B4C-825B-4BBC-9C4B-105B1FDBB253"),

        MaestroButton:new(3, deck, hsIcon("pptx/colors/fill-purple.png"), "EE2F4019-8615-4A6C-9CE8-840D9FA27778"),
        MaestroButton:new(11, deck, hsIcon("pptx/colors/line-purple.png"), "4AD5641B-4BAF-47D6-A6B8-D8D93041F23C"),
        MaestroButton:new(19, deck, hsIcon("pptx/colors/text-purple.png"), "09063A55-0CE1-4AE3-BAC2-8DF341AF619D"),

        MaestroButton:new(4, deck, hsIcon("pptx/colors/fill-yellow.png"), "70299E82-5094-44CD-98EB-EE783BE3FA0E"),
        MaestroButton:new(12, deck, hsIcon("pptx/colors/line-yellow.png"), "289D7C69-74B6-4127-B7EF-4C054EADD65E"),
        MaestroButton:new(20, deck, hsIcon("pptx/colors/text-yellow.png"), "E13771C5-F241-4C3A-8064-7765F6F30369"),

        MaestroButton:new(5, deck, hsIcon("pptx/colors/fill-orange.png"), "C4E8F125-C719-4125-A3A2-1492642DC054"),
        MaestroButton:new(13, deck, hsIcon("pptx/colors/line-orange.png"), "2AA28BE5-58A4-403C-8ABD-3FC69152E5B3"),
        MaestroButton:new(21, deck, hsIcon("pptx/colors/text-orange.png"), "F4CB8BE1-1199-4472-948F-07D5BBF11464"),

        MaestroButton:new(6, deck, hsIcon("pptx/colors/fill-green.png"), "EB427AC4-F6EE-4C4A-8972-47C7D91F1C92"),
        MaestroButton:new(14, deck, hsIcon("pptx/colors/line-green.png"), "D1E5B8B5-3160-4FF7-B6F3-F6812576AEFD"),
        MaestroButton:new(22, deck, hsIcon("pptx/colors/text-green.png"), "3634BCDF-9426-47ED-94DB-5A2B6AE29C66"),

        MaestroButton:new(7, deck, hsIcon("pptx/colors/fill-red.png"), "7E4D159E-F181-4D32-B567-033AD826CD6A"),
        MaestroButton:new(15, deck, hsIcon("pptx/colors/line-red.png"), "39368956-2C5B-41B6-8ACE-AC26D8BE2BFC"),
        MaestroButton:new(23, deck, hsIcon("pptx/colors/text-red.png"), "6D19B684-4DA2-4566-8F76-FCAACB39FED9"),

        MaestroButton:new(8, deck, hsIcon("pptx/colors/fill-inky-blue.png"), "796DFBC5-8B80-4422-9AA5-D19DE2A055D4"),
        MaestroButton:new(16, deck, hsIcon("pptx/colors/line-inky-blue.png"), "6769734A-DC6E-4D4E-9E20-641AD9197005"),
        MaestroButton:new(24, deck, hsIcon("pptx/colors/text-inky-blue.png"), "7F18E471-F989-4DA0-967D-1E935E3E0FC3"),

        -- TODO verify the action for these two:
        MaestroButton:new(27, deck, hsIcon("pptx/recording/record-pptx.png"), "B0F6834D-5E1D-4E08-AD92-3C2F87886CC0"),
        MaestroButton:new(28, deck, hsIcon("pptx/recording/record-mouse-only.png"), "C998899A-74A5-4329-8B94-6E1DE875F32B"),

    }

    print("myTestFunc took " .. GetElapsedTimeInMilliseconds(startTime) .. "ms")
end

FallbackProfiles:addProfilePage(DECK_2XL, PAGE_1, function(_, deck)
    return {
        -- row 4:
        LuaButton:new(31, deck, drawTextIcon("Timing hsIcon file", deck), timingHsIconFileOnly),
        LuaButton:new(32, deck, drawTextIcon("Timing Test", deck), timingHsCircleOnlyNoText)
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
