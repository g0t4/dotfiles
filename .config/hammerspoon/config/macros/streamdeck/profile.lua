---@class Profile
---@field name string
---@field appName string
---@field deckName string
local Profile = {}
Profile.__index = Profile

---@param name string @friendly name
---@param appName string @"Final Cut Pro", "iTerm2"
---@param deckName string @1XL, 2XL, 3XL, 4+
function Profile:new(name, appName, deckName)
    local o = setmetatable({}, Profile)
    o.name = name
    o.appName = appName
    o.deckName = deckName
    return o
end

---@param deck DeckController
function Profile:applyTo(deck)
    if deck.buttons ~= nil then
        deck.buttons:removeButtons()
        deck.buttons:addButtons(self:buttons(deck.deck))
        deck.buttons:start()
    end
    if deck.encoders ~= nil then
        deck.encoders:removeEncoders()
        deck.encoders:addEncoders(self:encoders(deck.deck))
        deck.encoders:start()
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
    return "Profile<" .. self.name .. ", " .. self.appName .. ", " .. self.deckName .. ">"
end

return Profile
