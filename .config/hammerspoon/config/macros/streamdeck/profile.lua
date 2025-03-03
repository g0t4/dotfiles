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
        -- modSetChange is an INTRA-APP event, in which case the likelihood of changes is lower... so we only reset the removed buttons (below)
        --   this doesn't apply to INTER-APP changes and page switches... these almost never have button overlap (wouldn't make sense to have overlap)
        --      so we always reset for these event types
        deck.hsdeck:reset()
    end

    if deck.buttons ~= nil then
        -- print("buttons - profile:" .. self.appName .. " applying to " .. deck.name)
        local buttonsBefore = deck.buttons.buttons
        -- local logBefore = f.concatKeys(buttonsBefore)
        -- print("  buttons before", logBefore)

        deck.buttons:removeButtons()
        deck.buttons:addButtons(self:buttons(deck))

        if isModSetChange then
            -- only if not reset:

            -- local logAfter = f.concatKeys(deck.buttons.buttons)
            -- print("  buttons after", logAfter)
            -- TODO if more than x% then reset deck instead?
            local buttonsAfter = deck.buttons.buttons
            f.each(buttonsBefore, function(btnNumberBefore, _btn)
                -- DO NOT USE ipairs (each uses pairs)
                if not buttonsAfter[btnNumberBefore] then
                    -- print("resetting button", btnNumberBefore)
                    resetButton(btnNumberBefore, deck.hsdeck)
                end
            end)
        end

        deck.buttons:start() -- for now just start all every time... b/c I have no button reuse logic yet (see brave profile for testing criteria and ideas)
        -- local notSameButtons = f.whereValues(deck.buttons.buttons, function(btn)
        --     return buttonsBefore[btn.buttonNumber] ~= btn
        -- end)
        -- -- print("  not same buttons", f.concatKeys(notSameButtons))
        -- f.eachValue(notSameButtons, function(btn)
        --     btn:start()
        -- end)
        -- local sameButtons = f.whereValues(deck.buttons.buttons, function(btn)
        --     return buttonsBefore[btn.buttonNumber] == btn
        -- end)
        -- if f.count(sameButtons) > 0 then
        --     print("  SAME BUTTONS DETECTED, MAKE SURE TO CHECK LOGIC in profile.lua for skipping calling START() on the same buttons")
        --     print("  same buttons", f.concatKeys(sameButtons))
        -- end

        --
    end
    if deck.encoders ~= nil then
        -- TODO clear encoders on mod set changes
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
