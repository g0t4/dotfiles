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

_G.LOG_DETAILED_TIMING = false

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

        -- local startTime = get_time() -- TMP TIMING ANALYSIS

        deck.buttons:addButtons(self:buttons(deck))
        -- print("        addButtons(buttons()) " .. GetElapsedTimeInMilliseconds(startTime) .. "ms") -- TMP TIMING ANALYSIS

        if isModSetChange then
            -- startTime = get_time() -- TMP TIMING ANALYSIS
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
            -- print("        modSet resetButton()s " .. GetElapsedTimeInMilliseconds(startTime) .. "ms") -- TMP TIMING ANALYSIS
        end

        -- if _G.LOG_DETAILED_TIMING then startTime = get_time() end -- TMP TIMING ANALYSIS
        deck.buttons:start() -- for now just start all every time... b/c I have no button reuse logic yet (see brave profile for testing criteria and ideas)
        -- if _G.LOG_DETAILED_TIMING then print("        start() " .. GetElapsedTimeInMilliseconds(startTime) .. "ms") end -- TMP TIMING ANALYSIS - heaviest hitter, esp PPTX 2XL/3XL which are mostly hsIcon files
    end
    if deck.encoders ~= nil then
        if isModSetChange then
            print("TODO clear encoders on mod set changes")
            -- resetButton(encoder?)
        end
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
