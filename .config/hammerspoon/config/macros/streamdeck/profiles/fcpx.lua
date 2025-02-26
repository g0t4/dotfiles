---@class AppObserver
---@field profiles Profile[]
local AppObserver = {}
AppObserver.__index = AppObserver

---@return AppObserver
function AppObserver:new()
    local o = setmetatable({}, AppObserver)
    o.profiles = {}
    return o
end

function AppObserver:getProfile(deckName)
    -- TODO later add in app observations too (and allow updating profiles/buttons!)
    local profiles = require("config.macros.streamdeck.profiles.profiles")
    -- TODO local profiles = self.profiles
    for _, profile in ipairs(profiles) do
        if profile.deckName == deckName
            and profile.appName == "com.apple.FinalCut"
        then
            return profile
        end
    end
end

return AppObserver
