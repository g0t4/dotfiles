-- FYI for type annotations, using class/inheritance:
--   https://github.com/LuaLS/lua-language-server/wiki/Annotations#class
--   ALSO a STELLAR annotations resource, lots of examples/caveats

-- GOALS:
-- - type annotations with generic button base to other functions
-- - some base logic is ok too (i.e. set button number, deck, etc), secondary goal btw

---@class PushButton
---@field buttonNumber number
---@field image hs.image|nil
---@field deck hs.streamdeck
local PushButton = {}

---@param buttonNumber number
---@param deck hs.streamdeck
---@param image hs.image|nil
---@return PushButton
function PushButton:new(buttonNumber, deck, image)
    -- remember, :new( == .new(self ... and whatever is left of :new is passed as self...
    --   so   PushButton:new(1, deck) is the same as PushButton.new(PushButton, 1, deck)

    -- Two needs from this ctor:
    -- 1. "inherit" metatable of PushButton (for its functions)
    -- 2. set base fields (buttonNumber, deck)
    local o = {} -- new object (no "type" yet)
    -- FYI new tables don't have a metatable
    -- FYI self here points to the implicit self param (that becomes the metatable)
    setmetatable(o, {
        __index = self,
        __tostring = self.__tostring
    })
    o.buttonNumber = buttonNumber
    o.deck = deck
    o.image = image
    return o
end

function PushButton:start()
    if self.image == nil then
        return
    end
    self.deck:setButtonImage(self.buttonNumber, self.image)
end

function PushButton:stop()
    -- TODO this shouldn't be needed here... do a review of cleanup at some point
    -- resetButton(self.buttonNumber, self.deck)
end

function PushButton:pressed()
end

function PushButton:released()
end

function PushButton:__tostring()
    return "PushButton: " .. (self.buttonNumber or "nil")
end

-- TODO add test case of __tostring since it can be frustrating to say the least
-- local test = PushButton:new(1, {}, nil)
-- assert(tostring(test) == "PushButton: 1")

return PushButton
