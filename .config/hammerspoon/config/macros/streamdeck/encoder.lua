--



--- Dial + Screen on Plus models
---@class Encoder
---@field number number
---@field deck hs.streamdeck
---@field screenImage hs.image|nil
local Encoder = {}

---@param number number
---@param deck hs.streamdeck
---@param screenImage hs.image|nil
---@return Encoder
function Encoder:new(number, deck, screenImage)
    local o = setmetatable({}, { __index = self })
    o.number = number
    o.deck = deck
    o.screenImage = screenImage
    return o
end

function Encoder:start()
    self.deck:setScreenImage(self.number, self.screenImage)
end

function Encoder:stop()
end

function Encoder:pressed()
end

function Encoder:released()
end

-- TODO screen swiped?

function Encoder:rotatedLeft()
end

function Encoder:rotatedRight()
end

return Encoder
