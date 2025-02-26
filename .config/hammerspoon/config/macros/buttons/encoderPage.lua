---@class EncoderPage
---@field encoders table<number, Encoder>
---@field private _numberOfEncoders number
---@field private _screen table<string, number>
---@field deck hs.streamdeck
local EncoderPage = {}
EncoderPage.__index = EncoderPage


---@param deck hs.streamdeck
---@return EncoderPage
function EncoderPage:newPlus(deck)
    local o = setmetatable({}, self)
    o.deck = deck
    o._numberOfEncoders = 4
    -- TODO confirm height/width
    o._screen = {
        width = 800,
        height = 600,
    }
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
    for encoderNumber = 1, self._numberOfEncoders do
        local encoder = self.encoders[encoderNumber]
        if encoder then
            encoder:start()
        else
            -- clear/reset one button with transparent image:
            local image = hsIcon("blank/transparent.svg")
            self.deck:setScreenImage(encoderNumber, image)
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

---@param interaction string
---@param xStart number
---@param yStart number
---@param xStop number
---@param yStop number
function EncoderPage:onScreenTouched(interaction, xStart, yStart, xStop, yStop)
    -- figure out which encoder region the first coordinate is in
    local pixelsPerEncoder = self._screen.width / self._numberOfEncoders
    local startEncoderNumber = math.floor(xStart / pixelsPerEncoder) + 1
    if startEncoderNumber > self._numberOfEncoders then
        print("start encoder not mapped: " .. startEncoderNumber)
        return
    end

    -- PRN if need to interact with the encoder:
    -- local encoder = self.encoders[encoderNumber]
    -- if not encoder then
    --     print("encoder not mapped: " .. encoderNumber)
    --     return
    -- end

    --  "shortPress", "longPress" or "swipe"
    -- for "shortPress" and "longPress" only use xFirst/yFirst, b/c xLast/yLast are 0
    local message = interaction .. " screen "
    if interaction == "swipe" then
        stopEncoderNumber = math.floor(xStop / pixelsPerEncoder) + 1
        if stopEncoderNumber > self._numberOfEncoders then
            print("stop encoder not mapped: " .. stopEncoderNumber)
            return
        end
        message = message .. "from " .. startEncoderNumber ..
            " (" .. xStart .. ", " .. yStart .. ")" ..
            " to " .. stopEncoderNumber .. " (" .. xStop .. ", " .. yStop .. ")"
        print(message)
        return
    end

    -- short/longPress:
    assert(xStop == 0, "xLast must be 0 for interactions other than swipe")
    assert(yStop == 0, "yLast must be 0 for interactions other than swipe")
    message = message .. "above encoder " .. startEncoderNumber ..
        " (" .. xStart .. ", " .. yStart .. ")"
    print(message)

    -- FYI encoder # is not tied to screen touches
    --   PRN decouple screen image from encoder button? if that makes sense go for it..
    --   I only mention this b/c the screen interactions are all treated as one type of event (not per encoder area)
    --   that is for swipes most likely but also can press on screen and so yeah... figure out how to use that!
    --   can probably tap on screen to change the functionality of an encoder!
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
