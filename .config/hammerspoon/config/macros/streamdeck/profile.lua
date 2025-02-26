---@class Profile
local Profile = {}
Profile.__index = Profile

function Profile:new(name, appBundleId, deckIdentifier)
    o = setmetatable({}, self)
    self.name = name
    self.appBundleId = appBundleId
    self.deckIdentifier = deckIdentifier
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
