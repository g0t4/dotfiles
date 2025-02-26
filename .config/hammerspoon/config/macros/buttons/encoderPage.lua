---@class EncoderPage
---@field encoders table<number, Encoder>
---@field numberOfEncoders number
---@field deck hs.streamdeck
local EncoderPage = {}
EncoderPage.__index = EncoderPage


---@param deck hs.streamdeck
---@return EncoderPage
function EncoderPage:newPlus(deck)
    local o = setmetatable({}, self)
    o.deck = deck
    o.numberOfEncoders = 4
    o.encoders = {}
    return o
end

function EncoderPage:addEncoder(encoder)
    self.encoders[encoder.number] = encoder
end

function EncoderPage:addEncoders(...)
    for _, encoder in ipairs({ ... }) do
        self:addEncoder(encoder)
    end
end

function EncoderPage:start()
    for encoderNumber = 1, self.numberOfEncoders do
        local encoder = self.encoders[encoderNumber]
        if encoder then
            encoder:start()
        else
            -- TODO how do I reset the screen image w/o full reset?
            local image = hsIcon("blank/black.png")
            self.deck:setScreenImage(encoderNumber, image)
            -- ("'/Users/wesdemos/repos/github/g0t4/dotfiles/misc/hammerspoon-icons/blank/black.png'
            -- self.deck:setScreenImage(encoderNumber, nil) -- FAILS
        end
    end
end

function EncoderPage:stop()
    -- for now just call stop on all encoders... to stop dynamic updates
    -- PRN and mark smth to stop reacting to keypresses
    for _, encoder in pairs(self.encoders) do
        encoder:stop()
    end
end

function EncoderPage:onScreenPressed(pressedOrReleased)
    -- TODO
end

function EncoderPage:onEncoderPressed(encoderNumber, pressedOrReleased, turnedLeft, turnedRight)
    local encoder = self.encoders[encoderNumber]
    if not encoder then
        print("encoder not mapped: " .. encoderNumber)
        return
    end

    local message = "encoder " .. encoderNumber

    if pressedOrReleased then
        message = message .. " pressed"
    else
        -- if left/right turn then release is not relevant
        if turnedLeft then
            message = message .. " left"
        elseif turnedRight then
            message = message .. " right"
        else
            -- only release event IF not left nor right
            message = message .. " released"
        end
    end
    print(message)
end

return EncoderPage
