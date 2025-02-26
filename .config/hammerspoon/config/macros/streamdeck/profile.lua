---@class Profile
---@field name string
---@field appBundleId string
---@field deckIdentifier string
local Profile = {}
Profile.__index = Profile

---@param name string @friendly name
---@param appBundleId string @com.apple.FinalCut, com.apple.iMovie, com.apple.Terminal
---@param deckIdentifier string @1XL, 2XL, 3XL, 4+
function Profile:new(name, appBundleId, deckIdentifier)
    local o = setmetatable({}, Profile)
    o.name = name
    o.appBundleId = appBundleId
    o.deckIdentifier = deckIdentifier
    return o
end

---@param deck DeckController
function Profile:applyTo(deck)
    if deck.buttons ~= nil then
        deck.buttons:addButtons(self:buttons(deck.deck))
    end
    if deck.encoders ~= nil then
        deck.encoders:addEncoders(self:encoders(deck.deck))
    end
end

---override in subclasses for specific profiles
---@param deck hs.streamdeck
---@return PushButton[] buttons
function Profile:buttons(deck)
    return {}
end

--- override in subclasses for specific profiles
---@param deck hs.streamdeck
---@return Encoder[] encoders
function Profile:encoders(deck)
    return {}
end

function Profile:__tostring()
    return "Profile<" .. self.name .. ", " .. self.appBundleId .. ", " .. self.deckIdentifier .. ">"
end

return Profile
