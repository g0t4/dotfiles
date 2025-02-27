-- global toggle to enable/disable verbose logging w.r.t. streamdeck "subsystem"
local verboseStreamDeckLogsOn = false -- make it easy to toggle (maybe even more this into hammerspoon init.lua?.. if I add more like it)
local log = require("hs.logger").new("streamdeck", verboseStreamDeckLogsOn and "verbose" or "warning")
local hsIcons = resolveHomePath("~/repos/github/g0t4/dotfiles/misc/hammerspoon-icons/")

function hsIcon(relativePath)
    local path = hsIcons .. relativePath
    local image = hs.image.imageFromPath(path)
    if image ~= nil then
        return image
    end
    error("hsIcons: could not load image from path:", path)
end

-- do not need to put everythin on the module...
--   verbose could easily overlap with the same name in other "subsystems" of my hammerspoon config
--   so lets make that clear so I don't have to namespace it to sdVerbose...
local M = {}

function M.verbose(...)
    log.v(...)
end

-- local blankTransparentSVG = hsIcon("blank/transparent.svg")
-- local blankBlack720PNG = hsIcon("blank/black-720x720.png")
local blankBlack288ElgatoPNG = hsIcon("blank/black-288x288-elgato-resized-identital-across-xl-and-plus.png")

---@param buttonNumber number
---@param deck hs.streamdeck
function resetButton(buttonNumber, deck)
    -- TODO can I speed up by creating an ideal resolution image (72x72, 144x144, 288x288-elgaot's app resized to this size)
    -- deck:setButtonColor(buttonNumber, hs.drawing.color.x11.black) -- 70 to 90ms
    -- deck:setButtonImage(buttonNumber, blankTransparentSVG) -- 70ms to 90ms too
    -- deck:setButtonImage(buttonNumber, blankBlack720PNG) -- 190ms!!!
    deck:setButtonImage(buttonNumber, blankBlack288ElgatoPNG) -- 90 to 100ms (better)
    -- FTR 90/100ms feels super fast in my testing
    -- TODO try other sizes? look at code under hood for what is gonna work best?
    -- ! 96x96 on XL, 120x120 on Plus RIGHT?

    -- TODO idea... reset and then set one button to stop the logo from staying on? is there a setting to turn it off?
    --  elgato app has a setting for changing the logo screen.. use it if needed
end

function getDeckName(deck)
    -- CL start
    --  + 9 end => deck 1XL
    --  + 1 end => deck 2XL
    --  + 8 end => deck 3XL
    -- A start (also ends with 4) => deck 4+

    local serial = deck:serialNumber()
    if serial:find("9$") then
        return "1XL"
    elseif serial:find("1$") then
        return "2XL"
    elseif serial:find("8$") then
        return "3XL"
    elseif serial:find("^A") then
        return "4+"
    end
    return "unknown"
end

function appIcon(bundleId)
    local icon = hs.image.imageFromAppBundle(bundleId)
    if icon ~= nil then
        return icon
    end
    error("appIcon: could not load image from app:", bundleId)

    -- alternatively, use hs.application.find(appName):icon()?
    -- or:
    -- /Applications/Hammerspoon.app/Contents/Resources/AppIcon.icns
end

function appIconHammerspoon()
    return appIcon("org.hammerspoon.Hammerspoon")
end

return M
