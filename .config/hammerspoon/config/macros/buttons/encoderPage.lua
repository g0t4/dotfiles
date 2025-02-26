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
    if interaction == "swipe" then
        stopEncoderNumber = math.floor(xStop / pixelsPerEncoder) + 1
        if stopEncoderNumber > self._numberOfEncoders then
            print("stop encoder not mapped: " .. stopEncoderNumber)
            return
        end



        -- compute velocity of swipe?
        --   swipe appears to be time constrained, not based on when I pickup my finger
        --   so, distance traveled is directly proportional to speed of swipe
        local xDistance = math.abs(xStop - xStart)
        local yDistance = math.abs(yStop - yStart)
        local distance = math.floor(math.sqrt(math.pow(xDistance, 2) + math.pow(yDistance, 2)))


        -- compute orientation? swipe up/down, left/right, or diagonal left/right? can map each to different actions
        local ratio = math.floor(xDistance / yDistance * 1000) / 1000
        local direction = ""
        -- FYI ratio > 5 worked well too in initial testing.. .if 4 is too low
        --   just test the gesture near the boundary between directions
        local threshold = 4
        if ratio > threshold then
            -- horizontal swipe
            if xStop > xStart then
                -- PRN use up/down left/right so its distinct versus diagonal swipes?
                --    also, up/down/left/right is easier to understand
                direction = "right"
                -- direction = "east"
            else
                direction = "left"
                -- direction = "west"
            end
        elseif ratio < (1 / threshold) then
            -- vertical swipe
            if yStop > yStart then
                direction = "down"
                -- direction = "south"
            else
                direction = "up"
                -- direction = "north"
            end
        else
            if xStop > xStart then
                if yStop > yStart then
                    direction = "south-east"
                else
                    direction = "north-east"
                end
            else
                if yStop > yStart then
                    direction = "south-west"
                else
                    direction = "north-west"
                end
            end
        end


        local message = interaction ..
            " " .. direction ..
            " " .. distance .. " pixels" ..
            " from enc" .. startEncoderNumber ..
            " (" .. xStart .. ", " .. yStart .. ")" ..
            " to enc" .. stopEncoderNumber .. " (" .. xStop .. ", " .. yStop .. ")"
        print(message)
        return
    end

    -- short/longPress:
    assert(xStop == 0, "xLast must be 0 for interactions other than swipe")
    assert(yStop == 0, "yLast must be 0 for interactions other than swipe")
    local message = interaction ..
        "above encoder " .. startEncoderNumber ..
        " at (" .. xStart .. ", " .. yStart .. ")"
    print(message)
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
