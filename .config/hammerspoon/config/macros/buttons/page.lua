require("config.macros.buttons.helpers")

---various types for holding sets of buttons
--
---XLPage => 8 cols x 4 rows - 96x96
---PlusPage => 4cols x 2 rows - 120x120 (IIRC)
---PlusEncoderPage => 4 encoders (one screen each, plus dial)
--

---@class ButtonPage
---@field deck hs.streamdeck
---@field rows number
---@field cols number
---@field buttons table<number, Button> @TODO button abstraction
local ButtonPage = {}
ButtonPage.__index = ButtonPage


---@param deck hs.streamdeck
---@param rows number
---@param cols number
---@return ButtonPage
function ButtonPage:new(deck, rows, cols)
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
---@return ButtonPage
function ButtonPage:newXL(deck)
    return ButtonPage:new(deck, 4, 8)
end

---@param deck hs.streamdeck
---@return ButtonPage
function ButtonPage:newPlus(deck)
    return ButtonPage:new(deck, 2, 4)
end

-- TODO button abstraction for all button types?
function ButtonPage:addButton(button)
    -- !!! TODO does the button need to know which number it is?
    -- !!! TODO likewise why does it know its deck?
    self.buttons[button.buttonNumber] = button
end

function ButtonPage:start()
    for rowNumber = 1, self.rows do
        for colNumber = 1, self.cols do
            local buttonNumber = rowNumber * self.cols + colNumber
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
        verbose("exec Page: " .. rowNumber .. " " .. colNumber)
    end
end

function ButtonPage:stop()
    -- for now just call stop on all buttons... to stop dynamic updates
    -- PRN and mark smth to stop reacting to keypresses
    for buttonNumber, button in pairs(self.buttons) do
        button:stop()
    end
end

--- called when a button is pressed
---@param buttonNumber number
---@param pressedOrReleased boolean
function ButtonPage:onButtonPressed(buttonNumber, pressedOrReleased)
    local button = self.buttons[buttonNumber]
    if button then
        if pressedOrReleased then
            if button.pressed == nil then
                print("button does not have pressed method: " .. buttonNumber)
                return
            end
            button:pressed()
            return
        end
        -- PRN else case... for triggering on release... use button.released in that case
    else
        print("button not mapped: " .. buttonNumber)
    end
end

return ButtonPage
