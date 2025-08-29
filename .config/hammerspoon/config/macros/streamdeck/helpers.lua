-- global toggle to enable/disable verbose logging w.r.t. streamdeck "subsystem"
local verboseStreamDeckLogsOn = false -- make it easy to toggle (maybe even more this into hammerspoon init.lua?.. if I add more like it)
if not verboseStreamDeckLogsOn then
    print("streamdeck: VERBOSE LOGGING IS OFF")
end
local log = require("hs.logger").new("streamdeck", verboseStreamDeckLogsOn and "verbose" or "warning")
local hsIcons = resolveHomePath("~/repos/github/g0t4/dotfiles/misc/hammerspoon-icons/")

hsIconCache = {}
function hsIcon(relativePath)
    local path = hsIcons .. relativePath

    local startTime = get_time()
    local cached = hsIconCache[relativePath]
    local ms = get_time() - startTime
    if ms > 0.1 then
        -- make sure this doesn't slow way down
        print("  time: hsIcons: cache check took", ms, "ms")
    end

    if cached ~= nil then
        -- print("HIT")
        return cached
    end
    local image = hs.image.imageFromPath(path)
    if image ~= nil then
        hsIconCache[relativePath] = image
        return image
    end
    error("hsIcons: could not load image from path:" .. path)
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

---@param buttonNumber integer
---@param hsdeck hs.streamdeck
function resetButton(buttonNumber, hsdeck)
    hsdeck:setButtonColor(buttonNumber, hs.drawing.color.x11.black) -- 70 to 90ms

    -- hsdeck:setButtonImage(buttonNumber, blankTransparentSVG) -- 70ms to 90ms too
    -- hsdeck:setButtonImage(buttonNumber, blankBlack720PNG) -- 190ms!!!
    -- hsdeck:setButtonImage(buttonNumber, blankBlack288ElgatoPNG) -- 90 to 100ms (better)
    -- FTR 90/100ms feels super fast in my testing

    -- TODO try other sizes? look at code under hood for what is gonna work best?
    -- !!! 96x96 on XL, 120x120 on Plus RIGHT?
    --  I still suspect image sizing will make a big difference...
    --   also curious how the standby screen works?
    --     IIAC it caches the image for each button device...
    --     it takes < 0.3ms to set every ICON!!!  even with custom standby screen
    --     why is it so fast?
    --     IIAC it's device sized icons
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

AppModuleLookupByAppTitle = {
    [APPS.FinalCutPro] = "fcpx",
    [APPS.Hammerspoon] = "hammerspoon",
    [APPS.PowerPoint] = "pptx",
    [APPS.Finder] = "finder",
    [APPS.iTerm] = "iterm",
    [APPS.BraveBrowserBeta] = "brave",
    -- [APPS.Safari] = "safari",
    -- [APPS.Preview] = "preview",

    -- profiles that aren't app specific, but rather are "fallbacks" when an app doesn't claim a deck
    [APPS.Testing] = "testing",
    [APPS.Defaults] = "defaults",
}

---@param appTitle string
function AppModuleName(appTitle)
    return AppModuleLookupByAppTitle[appTitle]
end

return M
