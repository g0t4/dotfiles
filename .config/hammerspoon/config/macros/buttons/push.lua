-- FYI for type annotations, using class/inheritance:
--   https://github.com/LuaLS/lua-language-server/wiki/Annotations#class
--   ALSO a STELLAR annotations resource, lots of examples/caveats

-- GOALS:
-- - type annotations with generic button base to other functions
-- - some base logic is ok too (i.e. set button number, deck, etc), secondary goal btw

---@class PushButton
---@field buttonNumber number
---@field deck hs.streamdeck
local PushButton = {}
PushButton.__index = PushButton

---@param buttonNumber number
---@param deck hs.streamdeck
---@return PushButton
function PushButton:new(buttonNumber, deck)
    -- remember, :new( == .new(self ... and whatever is left of :new is passed as self...
    --   so   PushButton:new(1, deck) is the same as PushButton.new(PushButton, 1, deck)
    -- therefore, we need to create a new table (object) and have it "inherit" from PushButton's metatable
    --   think JS likly prototypical inheritance
    local o = setmetatable({}, self)
    o.buttonNumber = buttonNumber
    o.deck = deck
    return o
end

function PushButton:start()
end

function PushButton:stop()
end

function PushButton:pressed()
end

function PushButton:released()
end

return PushButton
