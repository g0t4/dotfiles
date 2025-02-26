require("config.macros.streamdeck.helpers")

---@class ButtonsController
---@field deck hs.streamdeck
---@field rows number
---@field cols number
---@field buttons table<number, PushButton>
local ButtonsController = {}
ButtonsController.__index = ButtonsController


---@param deck hs.streamdeck
---@param rows number
---@param cols number
---@return ButtonsController
function ButtonsController:new(deck, rows, cols)
    local o = {}
    setmetatable(o, self)
    -- TODO do I need the deck here?
    o.deck = deck
    o.rows = rows
    o.cols = cols
    o.buttons = {}
    return o
end

---@param deck hs.streamdeck
---@return ButtonsController
function ButtonsController:newXL(deck)
    return ButtonsController:new(deck, 4, 8)
end

---@param deck hs.streamdeck
---@return ButtonsController
function ButtonsController:newPlus(deck)
    return ButtonsController:new(deck, 2, 4)
end

---@param button PushButton
function ButtonsController:addButton(button)
    self.buttons[button.buttonNumber] = button
end

---@param buttons PushButton[]
function ButtonsController:addButtons(buttons)
    for _, button in ipairs(buttons) do
        self:addButton(button)
    end
end

function ButtonsController:start()
    for buttonNumber = 1, self.rows * self.cols do
        local button = self.buttons[buttonNumber]
        if button then
            button:start()
        else
            -- reset flashes the splash screen (very noticeable)
            -- but, changes w/o reset are not noticeable
            --   and set background black effectively resets (if it had smth previously)
            -- TODO when I set the color, is that using an image?
            --   if so is that at all slow if done for every "blank" button?
            --   if so maybe create the blank image?
            --     optimized for the button size too?
            --     i.e. 96x96 for XL, 120x120 for Plus
            --   measure perf of either approach

            -- TODO move this to a deck wrapper type that I can use to add my own deck logic
            -- i.e.:
            --   mydeck:resetButton(buttonNumber)
            resetButton(buttonNumber, self.deck)
        end
    end
end

function ButtonsController:clearButtons()
    print("clearing buttons")
    for buttonNumber = 1, self.rows * self.cols do
        resetButton(buttonNumber, self.deck)
    end
end

function ButtonsController:stop()
    -- for now just call stop on all buttons... to stop dynamic updates
    -- PRN and mark smth to stop reacting to keypresses
    for _, button in pairs(self.buttons) do
        button:stop()
    end
end

--- called when a button is pressed
---@param buttonNumber number
---@param pressedOrReleased boolean
function ButtonsController:onButtonPressed(buttonNumber, pressedOrReleased)
    local button = self.buttons[buttonNumber]
    if not button then
        print("button not mapped: " .. buttonNumber)
        return
    end

    if pressedOrReleased then
        if button.pressed == nil then
            print("button does not have pressed method: " .. buttonNumber)
            return
        end
        button:pressed()
        return
    end
    -- PRN else case... for triggering on release... use button.released in that case
end

return ButtonsController
