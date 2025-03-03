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
        print("buttons - profile:", self.name, "applying to", deck.name)
        local buttonsBefore = deck.buttons.buttons
        local logBefore = f.concatKeys(buttonsBefore)
        print("  buttons before", logBefore)

        deck.buttons:removeButtons()
        deck.buttons:addButtons(self:buttons(deck))

        if isModSetChange then
            -- only if not reset:
            local logAfter = f.concatKeys(deck.buttons.buttons)
            print("  buttons after", logAfter)
            -- TODO if more than x% then reset deck instead?
            local buttonsAfter = deck.buttons.buttons
            f.each(buttonsBefore, function(btnNumberBefore, _btn)
                -- DO NOT USE ipairs (each uses pairs)
                if not buttonsAfter[btnNumberBefore] then
                    print("resetting button", btnNumberBefore)
                    resetButton(btnNumberBefore, deck.hsdeck)
                end
            end)
            -- TODO MOVE more of this into profile and let it handle all of this before/after
        end

        -- TODO stop recreating buttons EVERY TIME... right now they app appear new b/c they are new tables each time...
        --   OR add identtiy to buttons (more work)... how about try caching buttons (should speed up changes too)
        --   TODO once same buttons between runs, then make sure not :start()ing again works
        --
        -- PRN compute list of buttons that are the same so we can skip setting their image again?
        local notSameButtons = f.whereValues(deck.buttons.buttons, function(btn)
            return buttonsBefore[btn.buttonNumber] ~= btn
        end)
        -- print("  not same buttons", f.concatKeys(notSameButtons))
        f.eachValue(notSameButtons, function(btn)
            btn:start()
        end)
        local sameButtons = f.whereValues(deck.buttons.buttons, function(btn)
            return buttonsBefore[btn.buttonNumber] == btn
        end)
        if f.count(sameButtons) > 0 then
            print("  SAME BUTTONS DETECTED, MAKE SURE TO CHECK LOGIC in profile.lua for skipping calling START() on the same buttons")
            print("  same buttons", f.concatKeys(sameButtons))
        end
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
