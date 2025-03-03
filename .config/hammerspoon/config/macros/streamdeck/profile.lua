local f = require("config.helpers.underscore")

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
---@param isModSetChange boolean|nil
function Profile:applyTo(deck, isModSetChange)
    if not isModSetChange then
        -- FYI ideally I would makde decision on reset based on timing of resetButton vs # of buttons removed (cleared) vs previous set of buttons
        --    I am close to being able to do that comparison now that I have before/after logic below
        -- TODO move into profile too?
        -- don't reset on mod set changes (subset of buttons change is all)
        deck.hsdeck:reset()
    end

    if deck.buttons ~= nil then
        local buttonsBefore = deck.buttons.buttons
        deck.buttons:removeButtons()
        deck.buttons:addButtons(self:buttons(deck))
        -- TODO if more than x% then reset deck instead?
        for _, before in ipairs(buttonsBefore) do
            if not deck.buttons.buttons[before.buttonNumber] then
                -- clear button
                -- TODO setup new clear button using colors instead? or image? or?
                resetButton(before.buttonNumber, deck.hsdeck)
            end
        end
        -- TODO MOVE all of applyTo into profile and let it handle all of this before/after
        deck.buttons:start()
    end
    if deck.encoders ~= nil then
        deck.encoders:removeEncoders()
        deck.encoders:addEncoders(self:encoders(deck))
        deck.encoders:start()
    end
end

---override in subclasses for specific profiles
---@param deck DeckController
---@return PushButton[] buttons
function Profile:buttons(deck)
    return {}
end

--- override in subclasses for specific profiles
---@param deck DeckController
---@return Encoder[] encoders
function Profile:encoders(deck)
    return {}
end

function Profile:__tostring()
    return "Profile<" .. self.name .. ", " .. self.appName .. ", " .. self.deckName .. ">"
end

return Profile
